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

# prints board_msg
.macro	boardmsg
    la  $a0, board_msg
    li  $v0, 4			# syscall 4 = print string
    syscall
.end_macro

# prints move_msg
.macro	moveprompt
    la  $a0, move_msg
    li  $v0, 4			# syscall 4 = print string
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

# ADD NEXT PART OF PROGRAM HERE:

gameplay:
            boardmsg
            jal	    p_board
            
# make move
            moveprompt
            scan(move_inp, 6)
# parsing move input
        lbu $t1, move_inp+0($0)	# $t0 = O, F, U, D
        # determine location in memory
        
        li $t2, 0
        
        lbu     $t3, move_inp+2($t2)    # $t3 = row (ABCDEFGH)
        lbu     $t4, move_inp+3($t2)    # $t4 = col (12345678)
        cellno($t3,$t4,$t5)         # offset for where byte is, stores value at $t5. USES $t0 (wipes value)
# end of make move	

	    move $a0, $t5		# $a0 as 'cellno' parameter for functions

	    la	$t6, move_choices
	    
	    lb	$t2, 0($t6)
	    beq	$t1, $t2, open
	    
	    lb	$t2, 1($t6)
	    beq	$t1, $t2, flag
	    
	    lb	$t2, 2($t6)
	    beq	$t1, $t2, unflag
	    
	    lb	$t2, 3($t6)
	    beq	$t1, $t2, done
	    
	    j	gameplay

            # j       end

# END OF MAIN SECTION

# IMPLEMENT FUNCTIONS HERE:

#print_board()
p_board:
            la	    $t0, board
            li	    $t1, 0		# counter for loop
            li	    $t2, 64		# loop condition
            li      $t4, 8      # newline condition
            li      $t5, 0      # newline counter

pbd_loop:   lbu     $t3, 0($t0)			    # board[i]
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

pbm_loop:   lbu     $t3, 0($t0)			    # bombs[i]
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
#end of print_bombs()

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

#PLAYER MOVES

#open(cellno)
open:
	move    $t0, $a0		# cellno

    la  $a0, open_msg
    li  $v0, 4			# syscall 4 = print string
    syscall
    
    j	gameplay
#end of open()

#flag(cellno)
#still needs flags<7 condition
flag:
    addi    $sp, $sp, -8
    sw      $ra, 4($sp)
    sw      $s0, 0($sp)

    move    $s0, $a0             # $s0 = cellno
    
    la      $t0, board
    add     $t0, $t0, $s0
    
    # check if invalid    
    li	    $t1, '-'
    lb	    $t2, 0($t0)
    bne	    $t2, $t1, invalid
    
    # board[cellno] = 'F'
    li      $t1, 'F'
    sb      $t1, 0($t0)

    # check if(bombs[cellno]==9)
    la      $t2, bombs
    add     $t2, $t2, $s0
    lb      $t3, 0($t2)          # $t3 = bombs[cellno]
    li      $t4, 9               # $t4 = 9
    beq     $t3, $t4, f_bomb_found # if bombs[cellno] == 9, jump to bomb_found

    # else return 0
    li      $v0, 0               # $v0 = 0
    j       flag_end

f_bomb_found:
    #  return 1
    li      $v0, 1               # $v0 = 1

flag_end:
    lw      $s0, 0($sp)
    lw      $ra, 4($sp)
    addi    $sp, $sp, 8
    
    j	gameplay
#end of flag()

#unflag(cellno)
unflag:
    addi    $sp, $sp, -8
    sw      $ra, 4($sp)
    sw      $s0, 0($sp)

    move    $s0, $a0             # $s0 = cellno

    la      $t0, board
    add     $t0, $t0, $s0

    # check if invalid    
    li	    $t1, 'F'
    lb	    $t2, 0($t0)
    bne	    $t2, $t1, invalid
    
    # board[cellno] = '-'
    li      $t1, '-'
    sb      $t1, 0($t0)

    # check if(bombs[cellno]==9)
    la      $t2, bombs
    add     $t2, $t2, $s0
    lb      $t3, 0($t2)          # $t3 = bombs[cellno]
    li      $t4, 9               # $t4 = 9
    beq     $t3, $t4, u_bomb_found # if bombs[cellno] == 9, jump to bomb_found

    # else return 0
    li      $v0, 0               # $v0 = 0
    j       unflag_end

u_bomb_found:
    #  return -1
    li      $v0, -1               # $v0 = -1

unflag_end:
    lw      $s0, 0($sp)
    lw      $ra, 4($sp)
    addi    $sp, $sp, 8
    
    j	gameplay
#end of unflag()

#done(cellno)
done:
    la  $a0, done_msg
    li  $v0, 4			# syscall 4 = print string
    syscall
    
    j	end
#end of done()

#END OF PLAYER MOVES SECTION


#END OF FUNCTIONS SECTION

invalid:
    la  $a0, invalid_msg
    li  $v0, 4			# syscall 4 = print string
    syscall
    
    j	gameplay

end:        exit
#END OF PROGRAM

.data
bombs:  .space  64	# 8x8 board for bombs
board:  .space  64	# 8x8 board for the player
cell:   .space 22    # 7x2 bytes for cell location, 7 bytes for white space, 1 byte for null char
move_inp:	.space 6	# 1 byte for move, 2 bytes for cell location, 2 bytes for white space, 1 byte for null char
move_choices:	.asciiz "OFUD"
board_msg:	.asciiz "\nBOARD: \n"
move_msg:	.asciiz "MOVE: "
invalid_msg:	.asciiz "Invalid input\n"
win_msg:	.asciiz "\nWIN!\n"
lose_msg:	.asciiz "\nLOSE!\n"

# temp strings for checking only
open_msg:	.asciiz "Open\n"
done_msg:	.asciiz "Done\n"
