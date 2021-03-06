; Written for Exploring BeagleBone v2 by Derek Molloy
; This program uses the PRU as a PWM controller based on the values in
; 0x00000000 (percentage) and 0x00000004 (delay)
  .cdecls "main.c"
  .clink
  .global START
  .asg  32, PRU0_R31_VEC_VALID  ; allows notification of program completion
  .asg  3,  PRU_EVTOUT_0        ; the event number that is sent back

START:
        ; Reading the memory that was set by the C program into registers
        ; r1 - Read the PWM percent high (0-100)
        LDI32   r0, 0x00000000     ; load the memory location
        LBBO    &r1, r0, 0, 4      ; load the percent value into r1
        ; r2 - Load the sample time delay
        LDI32   r0, 0x00000004     ; load the memory location
        LBBO    &r2, r0, 0, 4      ; load the step delay value into r2
        ; r3 - The PWM precent that the signal is low (100-r1)
        LDI32   r3, 100            ; load 100 into r3
        SUB     r3, r3, r1         ; subtract r1 (high) away from 100
MAINLOOP:
        MOV     r4, r1             ; start counter at number of steps high
        SET     r30, r30.t5        ; set the output P9_27 high
SIGNAL_HIGH:
        MOV     r0, r2             ; the delay step length - load r2 above
DELAY_HIGH:
        SUB     r0, r0, 1          ; decrement delay loop counter
        QBNE    DELAY_HIGH, r0, 0  ; repeat until step delay is done
        SUB     r4, r4, 1          ; the signal was high for a step
        QBNE    SIGNAL_HIGH, r4, 0 ; repeat until signal high steps are done
        ; Now the signal is going to go low for 100%-r1% - i.e., r3
        MOV     r4, r3             ; number of steps low loaded
        CLR     r30, r30.t5        ; set the output P9_27 low
SIGNAL_LOW:
        MOV     r0, r2             ; the delay step length - load r2 above
DELAY_LOW:
        SUB     r0, r0, 1          ; decrement loop counter
        QBNE    DELAY_LOW, r0, 0   ; repeat until step delay is done
        SUB     r4, r4, 1          ; the signal was low for a step
        QBNE    SIGNAL_LOW, r4, 0  ; repeat until signal low % is done

        QBBS    END, r31, 3        ; quit if button on P9_28 is pressed
        QBA     MAINLOOP           ; otherwise loop forever
END:                               ; end of program, send back interrupt
        LDI32   R31, (PRU0_R31_VEC_VALID|PRU_EVTOUT_0)
        HALT                       ; halt the pru program
