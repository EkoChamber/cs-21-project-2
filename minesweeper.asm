# IGNORE SPACING FOR NOW, coding this in vscode instead of MARS (SHIT FORMATTING)
# we'll fix spacing in MARS once done with everything �?�?�?


# MACROS:
# exit macro
.macro      exit
    li $v0, 10
    syscall
.end_macro

# prints char at $reg. use lbu to a $reg then input here
.macro      printb(%reg)
    or  $a0, $0, %reg
    li  $v0, 11             # syscall 11 = print character
    syscall
.end_macro

# prints a new line char
.macro      newl
    li  $a0, 10             # ascii 10 = '\n'
    li  $v0, 11             # syscall 11 = print character
    syscall
.end_macro

# scans %len amt. of chars. NOTE: Label should have len+1 bytes allocated (+1 for null byte)
.macro      scan(%strlbl,%len)
    la  $a0, %strlbl        # label addr to input to
    li  $a1, %len           # length of string
    li  $v0, 8              # syscall 8 = read string
    syscall
.end_macro

# formula for cellno, stores result at %ret. also changes row and col registers to coordinates(?) (like A=1, B=2, etc.)
# ALSO WARNING: uses $t0
.macro      cellno(%row,%col,%ret)
    li      $t0, 8
    addi    %row, %row, -65     # 65 = 'A' in ascii
    addi    %col, %col, -49     # 48 = '1' in ascii
    mult	%row, $t0		    # %row * $t0 = Hi and Lo registers
    mflo	$t0                 # copy lo to $t0
    add     %ret, $t0, %col
.end_macro

.text
# REGISTERS TO SAVE:
# -$s0-$s7  (when needed)
# -$ra      (on recursion or nested fxn calls)
# -$a0-$a3  (use for function input, save for recursion/nested fxn calls)
# -$sp      (when using the stack)
#
# when a function doesnt need to save registers AT ALL, better to use $t0-$t9 registers so we dont need to worry abt the stack
# init $t0-$t9 to 0 or whatever value needed before use
# anything not on list, treat as temp register (no need to save)

# MAIN SECTION
main:
# note: no need to initialize bombs board for MARS since default value for words in data segment is 0

# initiallize player board
            la	    $t0, board
            li	    $t1, 0		# counter for loop
            li	    $t2, 64		# loop condition
            li	    $t3, 45		# ascii for "-"

bombsloop:  sb	    $t3, 0($t0)		# load "-" into byte in memory
            addi	$t0, $t0, 1		# next byte in memory
            addi	$t1, $t1, 1		# $t1++ (counter for loop)
            blt	    $t1, $t2, bombsloop	# if $t1 < 64, then loop

            # jal 	p_board     	#print board
# end of init player board. all registers are free to use

# plant bombs
            scan(cell, 22)
            jal     plant

	newl
            jal     p_bombs
# end of plant bombs
            j       end

# END OF MAIN SECTION

# IMPLEMENT FUNCTIONS HERE:

#print_board()
p_board:
            la	    $t0, board
            li	    $t1, 0		# counter for loop
            li	    $t2, 64		# loop condition
            li      $t4, 8      # newline condition
            li      $t5, 0      # newline counter

pbd_loop:   lbu     $t3, 0($t0)
            printb($t3)
            addi	$t0, $t0, 1		    # next byte in memory
            addi	$t1, $t1, 1		    # $t1++ (counter for loop)
            addi	$t5, $t5, 1		    # $t5++ (counter for newl)
            bne     $t5, $t4, skipn1    #if $t5!=8, dont add newline
            newl
            li      $t5, 0              #reset counter
skipn1:     blt	    $t1, $t2, pbd_loop	# if $t1 < 64 then loop

            jr	    $ra
#end of print_board()

#print_bombs()
p_bombs:
            la	    $t0, bombs
            li	    $t1, 0		# counter for loop
            li	    $t2, 64		# loop condition
            li      $t4, 8      # newline condition
            li      $t5, 0      # newline counter

pbm_loop:   lbu     $t3, 0($t0)
            ble     $t3, $t4, skipbcell     #check if cell is a bomb
# cell is a bomb
            li      $t3, 66     # 66 = 'B' in ascii
            j       skipprint
# cell is not a bomb
skipbcell:  addi    $t3, $t3, 48        # 48 = '0' in ascii

skipprint:  printb($t3)
            addi	$t0, $t0, 1		    # next byte in memory
            addi	$t1, $t1, 1		    # $t1++ (counter for loop)
            addi	$t5, $t5, 1		    # $t5++ (counter for newl)
            bne     $t5, $t4, skipn2    #if $t5!=8, dont add newline
            newl
            li      $t5, 0              #reset counter
skipn2:     blt	    $t1, $t2, pbm_loop	# if $t1 < 64 then loop

            jr	    $ra
#end of print_board()

#plant(string of locations)
plant:
        addi    $sp, $sp, -8
        sw      $s1, 4($sp)
        sw      $s0, 0($sp)

        li      $t1, 0		        # counter for loop
        li	    $t2, 21             # loop condition, 7 bombs x 3 bytes to go through
        li      $t9, 9              # when cell >9, cell contains bomb in bomb board
        li      $t6, 8              # multiply row
p_loop:
        # determine location in memory
        lbu     $t3, cell+0($t1)    # $t3 = row (ABCDEFGH)
        lbu     $t4, cell+1($t1)    # $t4 = col (12345678)
        cellno($t3,$t4,$t5)         # offset for where byte is, stores value at $t5. USES $t0 (wipes value)

        # write bomb
        sb      $t9, bombs+0($t5)   # store to byte at board+(int stored at $t5)


        # increment adjacent cells  (LOTS OF BRANCHES)
        li      $t7, 0
        li      $t8, 7


        # top left corner
        beq     $t3, $t7, ptl
        beq     $t4, $t7, ptl

        addi    $s0, $t3, -1        # 1 upwards
        addi    $s1, $t4, -1        # 1 to the left
        mult    $s0, $t6
        mflo    $s0
        add     $s0, $s0, $s1

        lb      $s1, bombs+0($s0)
        addi    $s1, $s1, 1
        sb      $s1, bombs+0($s0)
ptl:

        # top cell
        beq     $t3, $t7, ptc

        addi    $s0, $t3, -1        # 1 upwards
        addi    $s1, $t4, 0         # copy
        mult    $s0, $t6
        mflo    $s0
        add     $s0, $s0, $s1

        lb      $s1, bombs+0($s0)
        addi    $s1, $s1, 1
        sb      $s1, bombs+0($s0)
ptc:

        # top right corner
        beq     $t3, $t7, ptr
        beq     $t4, $t8, ptr

        addi    $s0, $t3, -1        # 1 upwards
        addi    $s1, $t4, 1         # 1 to the right
        mult    $s0, $t6
        mflo    $s0
        add     $s0, $s0, $s1

        lb      $s1, bombs+0($s0)
        addi    $s1, $s1, 1
        sb      $s1, bombs+0($s0)
ptr:

        # left cell
        beq     $t4, $t7, plc

        addi    $s0, $t3, 0         # copy
        addi    $s1, $t4, -1        # 1 to the left
        mult    $s0, $t6
        mflo    $s0
        add     $s0, $s0, $s1

        lb      $s1, bombs+0($s0)
        addi    $s1, $s1, 1
        sb      $s1, bombs+0($s0)
plc:

        # right cell
        beq     $t4, $t8, prc

        addi    $s0, $t3, 0         # copy
        addi    $s1, $t4, 1         # 1 to the right
        mult    $s0, $t6
        mflo    $s0
        add     $s0, $s0, $s1

        lb      $s1, bombs+0($s0)
        addi    $s1, $s1, 1
        sb      $s1, bombs+0($s0)
prc:

        # bot left corner
        beq     $t3, $t8, pbl
        beq     $t4, $t7, pbl

        addi    $s0, $t3, 1         # 1 downwards
        addi    $s1, $t4, -1        # 1 to the left
        mult    $s0, $t6
        mflo    $s0
        add     $s0, $s0, $s1

        lb      $s1, bombs+0($s0)
        addi    $s1, $s1, 1
        sb      $s1, bombs+0($s0)
pbl:

        # bot cell
        beq     $t3, $t8 pbc

        addi    $s0, $t3, 1         # 1 downwards
        addi    $s1, $t4, 0         # copy
        mult    $s0, $t6
        mflo    $s0
        add     $s0, $s0, $s1

        lb      $s1, bombs+0($s0)
        addi    $s1, $s1, 1
        sb      $s1, bombs+0($s0)
pbc:

        # bot right corner
        beq     $t3, $t8, pbl
        beq     $t4, $t8, pbl

        addi    $s0, $t3, 1         # 1 downwards
        addi    $s1, $t4, 1         # 1 to the right
        mult    $s0, $t6
        mflo    $s0
        add     $s0, $s0, $s1

        lb      $s1, bombs+0($s0)
        addi    $s1, $s1, 1
        sb      $s1, bombs+0($s0)
pbr:

        # end of increment adjacent cells
        addi    $t1, $t1, 3         # increment by 3
        blt     $t1, $t2, p_loop

        lw      $s0, 0($sp)
        lw      $s1, 4($sp)
        addi    $sp, $sp, 8
        jr      $ra
#end of plant()


#END OF FUNCTIONS SECTION

end:        exit
#END OF PROGRAM

.data
bombs:  .space  64	# 8x8 board for bombs
board:  .space  64	# 8x8 board for the player
cell:   .space 22    # 7x2 bytes for cell location, 7 bytes for white space, 1 byte for null char
