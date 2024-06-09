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

# gameplay loop

	li $s0, 0	# score
	li $s1, 0	# flags

gameplay:
            boardmsg
            jal	    p_board

# make move
            moveprompt
            scan(move_inp, 6)
# parsing move input
        lbu $t1, move_inp+0($0)	# $t0 = O, F, U, D
        # determine location in memory

        lbu     $a1, move_inp+2         # $t3 = row (ABCDEFGH)
        lbu     $a2, move_inp+3         # $t4 = col (12345678)
        cellno($a1,$a2,$a0)         # offset for where byte is, stores value at $a0. USES $t0 (wipes value)
# end of make move
	    la	$t6, move_choices

	    lb	$t2, 0($t6)
	    beq	$t1, $t2, open_decide

	    lb	$t2, 1($t6)
	    beq	$t1, $t2, flag

	    lb	$t2, 2($t6)
	    beq	$t1, $t2, unflag

	    lb	$t2, 3($t6)
	    beq	$t1, $t2, done

	    j	gameplay

# check if opened cell is bomb/opened/flagged when open is called
open_decide:
        lb  $t9, bombs+0($a0)
        lbu $t8, board+0($a0)
        li  $t3, 8
        li  $t4, '-'
        bne $t8, $t4, invalid   # check flag takes priority
        bgt $t9, $t3, lose      # over checking bomb
        jal open
        j gameplay  # return to loop

done:
        li	   $t0, 7
        bne	   $s0, $t0, lose

#win
        la  $a0, win_msg
        li  $v0, 4			# syscall 4 = print string
        syscall

        j winskip
    lose:
        la  $a0, lose_msg
        li  $v0, 4			# syscall 4 = print string
        syscall

    winskip:
        move  $a0, $s0
        li  $v0, 1			# syscall 1 = print int
        syscall

        la  $a0, score_msg
        li  $v0, 4			# syscall 4 = print string
        syscall

        jal end_board
        jal p_board

        j	end

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
        beq     $t3, $t8, pbr
        beq     $t4, $t8, pbr

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
        addi    $t1, $t1, 1         # increment by 1
        blt     $t1, $t2, p_loop

        lw      $s0, 0($sp)
        lw      $s1, 4($sp)
        addi    $sp, $sp, 8
        jr      $ra
#end of plant()

#PLAYER MOVES

#open(cellno,row,col)
# $a1 = row
# $a2 = column
# $a0 = cellno
open:
        addi    $sp, $sp, -20
        sw      $ra, 16($sp)
        sw      $s3, 12($sp)
        sw      $s2, 8($sp)
        sw      $s1, 4($sp)
        sw      $s0, 0($sp)

        # check if cell is opened already
        li	    $t2, '-'
        lb	    $t3, board+0($a0)
        bne	    $t3, $t2, obr       # obr here is return for this function

        # open cell at $a0
        lb      $t1, bombs+0($a0)
        addi    $t1, $t1, '0'
        sb      $t1, board+0($a0)

        # check if cell is not a 0 cell
        li      $t0, '0'
        bne     $t1, $t0, obr       # if($t1!='0') jump to obr

        # comparison registers for opening adjacent cells
        li      $t7, 0
        li      $t8, 7

        # multiply row
        li      $t6, 8

        # move $a1 and $a2 to $s0 and $s1 respectively
        move    $s0, $a1
        move    $s1, $a2

        # top left corner
        beq     $s0, $t7, otl
        beq     $s1, $t7, otl

        addi    $a1, $s0, -1        # 1 upwards
        addi    $a2, $s1, -1        # 1 to the left
        mult    $a1, $t6
        mflo    $s3
        add     $a0, $s3, $a2       # s3(rowx8) + col

        jal     open
otl:

        # top cell
        beq     $s0, $t7, otc

        addi    $a1, $s0, -1        # 1 upwards
        addi    $a2, $s1, 0         # copy
        mult    $a1, $t6
        mflo    $s3
        add     $a0, $s3, $a2       # s3(rowx8) + col

        jal     open
otc:

        # top right corner
        beq     $s0, $t7, otr
        beq     $s1, $t8, otr

        addi    $a1, $s0, -1        # 1 upwards
        addi    $a2, $s1, 1         # 1 to the right
        mult    $a1, $t6
        mflo    $s3
        add     $a0, $s3, $a2       # s3(rowx8) + col

        jal     open
otr:

        # left cell
        beq     $s1, $t7, olc

        addi    $a1, $s0, 0         # copy
        addi    $a2, $s1, -1        # 1 to the left
        mult    $a1, $t6
        mflo    $s3
        add     $a0, $s3, $a2       # s3(rowx8) + col

        jal     open
olc:

        # right cell
        beq     $s1, $t8, orc

        addi    $a1, $s0, 0         # copy
        addi    $a2, $s1, 1         # 1 to the right
        mult    $a1, $t6
        mflo    $s3
        add     $a0, $s3, $a2       # s3(rowx8) + col

        jal     open
orc:

        # bot left corner
        beq     $s0, $t8, obl
        beq     $s1, $t7, obl

        addi    $a1, $s0, 1         # 1 downwards
        addi    $a2, $s1, -1        # 1 to the left
        mult    $a1, $t6
        mflo    $s3
        add     $a0, $s3, $a2       # s3(rowx8) + col

        jal     open
obl:

        # bot cell
        beq     $s0, $t8 obc

        addi    $a1, $s0, 1         # 1 downwards
        addi    $a2, $s1, 0         # copy
        mult    $a1, $t6
        mflo    $s3
        add     $a0, $s3, $a2       # s3(rowx8) + col

        jal     open
obc:

        # bot right corner
        beq     $s0, $t8, obr
        beq     $s1, $t8, obr

        addi    $a1, $s0, 1         # 1 downwards
        addi    $a2, $s1, 1         # 1 to the right
        mult    $a1, $t6
        mflo    $s3
        add     $a0, $s3, $a2       # s3(rowx8) + col

        jal     open
obr:
        lw      $s0, 0($sp)
        lw      $s1, 4($sp)
        lw      $s2, 8($sp)
        lw      $s3, 12($sp)
        lw      $ra, 16($sp)
        addi    $sp, $sp, 20
        jr      $ra
#end of open()

#flag(cellno)
#may error w the score
flag:
    #removed stack allocation since not needed
    move    $t5, $a0             # $t5 = cellno

    # check if invalid
    li	    $t1, '-'
    lb	    $t2, board+0($a0)
    bne	    $t2, $t1, invalid

    # check if flags<7
    li	    $t1, 7
    beq	    $s1, $t1, invalid

    # board[cellno] = 'F'
    li      $t1, 'F'
    sb      $t1, board+0($a0)
    addi    $s1, $s1, 1     #increment flags register

    # check if(bombs[cellno]>8)
    lb      $t3, bombs+0($a0)    # $t3 = bombs[cellno]
    li      $t4, 8               # $t4 = 9
    bgt     $t3, $t4, f_bomb_found # if bombs[cellno] == 9, jump to bomb_found

    # else return
    j       flag_end

f_bomb_found:
    # add to score
    addi    $s0, $s0, 1     # score+= flag(cellno)

flag_end:
    lw      $t5, 0($sp)
    lw      $ra, 4($sp)
    addi    $sp, $sp, 8

    j	gameplay            # no need for jal/jr $ra for this function since we jump to loop again
#end of flag(cellno)

#unflag(cellno)
unflag:
    #removed stack allocation since not needed
    move    $t5, $a0             # $t5 = cellno

    # check if invalid
    li	    $t1, 'F'
    lb	    $t2, board+0($a0)
    bne	    $t2, $t1, invalid

    # board[cellno] = '-'
    li      $t1, '-'
    sb      $t1, board+0($a0)
    subi    $s1, $s1, 1

    # check if(bombs[cellno]>8)
    lb      $t3, bombs+0($a0)    # $t3 = bombs[cellno]
    li      $t4, 8               # $t4 = 9
    bgt     $t3, $t4, u_bomb_found # if bombs[cellno] == 9, jump to bomb_found

    # else return
    j       unflag_end

u_bomb_found:
    #  decrement score
    addi    $s0, $s0, -1    # score+= flag(cellno)

unflag_end:
    j	gameplay            # no need for jal/jr $ra for this function since we jump to loop again
#end of unflag(cellno)

# END OF PLAYER MOVES SECTION

# invalid function/label to jump to
invalid:
    la  $a0, invalid_msg
    li  $v0, 4			# syscall 4 = print string
    syscall

    j	gameplay            # no need for jal/jr $ra for this function since we jump to loop again

# function to change board to how it is when game ends
# - copies bombs board onto player board
# - when F is placed, if no bomb, then print X. If bomb, keep as is (as "F")
end_board:
        li      $t0, 0      # loop counter
        li      $t1, 64     # loop condition
        li      $t4, 8      # checking for bombs
        li      $t5, 'F'    # checking for flags
        li      $t6, 'X'    # for wrong flags
        li      $t7, 'B'    # for unflagged bombs

ebloop:
        lbu     $t2, board+0($t0)
        lb      $t3, bombs+0($t0)

        # case if cell is a flag
        bne     $t2, $t5, bombeb    #if not a flag, skip to bombeb
        bgt     $t3, $t4, skipeb    #if bomb, go next cell
        # if cell flagged is not a bomb:
        sb      $t6, board+0($t0)
        j       skipeb


bombeb:
        # if cell is unflagged bomb
        ble     $t3, $t4, normeb    #if not a bomb, skip to normeb
        sb      $t7, board+0($t0)
        j       skipeb

normeb:
        # if player board cell is '-' and not a bomb
        addi    $t3, $t3, '0'
        sb      $t3, board+0($t0)
skipeb:
        addi    $t0, $t0, 1
        blt     $t0, $t1, ebloop

        jr      $ra


#END OF FUNCTIONS SECTION

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
invalid_msg:	.asciiz "\nInvalid input"
win_msg:	.asciiz "\nWIN!\n"
lose_msg:	.asciiz "\nLOSE!\n"
score_msg:	.asciiz " of 7 bombs.\n"
