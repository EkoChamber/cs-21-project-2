# IGNORE SPACING FOR NOW, coding this in vscode instead of MARS (SHIT FORMATTING)
# we'll fix spacing in MARS once done with everything �?�?�?


# MACROS:
.macro      exit
    li $v0, 10
    syscall
.end_macro

.macro      printb(%reg)    # prints char at $reg. use lbu to a $reg then input here
    or  $a0, $0, %reg
    li  $v0, 11             # syscall 11 = print character
    syscall
.end_macro

.macro      newl            # prints a new line char
    li  $a0, 10             # ascii 10 = '\n'
    li  $v0, 11             # syscall 11 = print character
    syscall
.end_macro

.macro      scan(%strlbl,%len)  # scans %len amt. of chars. NOTE: Label should have len+1 bytes allocated (+1 for null byte)
    la  $a0, %strlbl        # label addr to input to
    li  $a1, %len           # length of string
    li  $v0, 8              # syscall 8 = read string
    syscall
.end_macro

.macro      cellno(%row,%col)   # formula for cellno, stores result at %row
    li      $t0, 8
    addi    %row, %row, -65     # 65 = 'A' in ascii
    addi    %col, %col, -48     # 48 = '0' in ascii
    mult	%row, $t0		    # %row * $t0 = Hi and Lo registers
    mflo	%row                # copy lo to %row
    add     %row, %row, %col
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
# end of init player board

# plant bombs
            la      $s0, bombs
            li	    $s1, 0		# counter for loop
            li	    $s2, 7		# loop condition (7 bombs to be placed)

plantloop:  scan(cell, 4)
            lbu     $s3, cell       # $s3 = row (ABCDEFGH)
            lbu     $s4, cell+1     # $s4 = col (12345678)
            or      $a1, $0, $s3    # copy row location
            or      $a2, $0, $s4    # copy col location
            cellno($s3,$s4)         # offset for where byte is, stores value at $s3
            or      $a0, $0, $s3    # copy $s3 to $a0
            jal     plant

            addi    $s1, $s1, 1     # $s1++
            blt     $s1, $s2, plantloop # if $s1 < 7, then loop

	newl
            jal     p_bombs

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

pbr_loop:   lbu     $t3, 0($t0)
            printb($t3)
            addi	$t0, $t0, 1		    # next byte in memory
            addi	$t1, $t1, 1		    # $t1++ (counter for loop)
            addi	$t5, $t5, 1		    # $t5++ (counter for newl)
            bne     $t5, $t4, skipn1    #if $t5!=8, dont add newline
            newl
            li      $t5, 0              #reset counter
skipn1:     blt	    $t1, $t2, pbr_loop	# if $t1 < 64 then loop

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
            addi    $t3, $t3, 48        # 48 = '0' in ascii
            printb($t3)
            addi	$t0, $t0, 1		    # next byte in memory
            addi	$t1, $t1, 1		    # $t1++ (counter for loop)
            addi	$t5, $t5, 1		    # $t5++ (counter for newl)
            bne     $t5, $t4, skipn2    #if $t5!=8, dont add newline
            newl
            li      $t5, 0              #reset counter
skipn2:     blt	    $t1, $t2, pbm_loop	# if $t1 < 64 then loop

            jr	    $ra
#end of print_board()

#plant(cellno, row, col) // we get values of row and col directly and use to check for edge/corner cells
plant:
        li  $t0, 9              # when cell >9, cell contains bomb in bomb board
        sb  $t0, bombs+0($a0)    # store to byte at board+(int stored at $a0)
        jr  $ra
#end of plant()


#END OF FUNCTIONS SECTION

end:        exit
#END OF PROGRAM

.data
bombs:  .space  64	# 8x8 board for bombs
board:  .space  64	# 8x8 board for the player
cell:   .space 4    # 2 bytes for cell location, 1 byte for white space,1 byte for null byte
