#include <stdio.h>

//implement in data segment
char bombs[64]={};  //table for bombs + adjacent cells
char board[64]={};  //table for the players view

/*
    2 arrays will be used
    1 for reference of where the bombs are and what number each cell should have
    another for what the player sees
*/


/*
    Functions to implement in MIPS:
    plant bomb  - DONE in C
    open bomb   - DONE in C
    flag bomb   - DONE in C
    unflag bomb - DONE in C
    open all unflagged and unopened cells (game end)
*/

//print board
void print_board(){
    for(int i=0; i<64;i++){
        if(i!=0 && i%8==0) printf("\n");
        printf("%c ", board[i]);
    }
    printf("\n");
}

//print bombs location
void print_bombs(){
    for(int i=0; i<64;i++){
        if(i!=0 && i%8==0) printf("\n");
        printf("%d ", bombs[i]);
    }
    printf("\n");
}

//open all unopened cells left (still have to call print_board after)
void end_game(){
    for(int i=0; i<64;i++){
        if(board[i]=='F' && bombs[i]!=9){
            board[i]='X';
        }
        else if(bombs[i]==9){
            board[i]='B';
            continue;
        }
        else board[i] = bombs[i] + '0';
    }
}

//plant bombs at the start of the game
void plant(char cell[2]){
    int cellno = 0;
    int neighbors[8] = {};
    cellno = ((cell[0]-'A')*8) + (cell[1]-'1');
    bombs[cellno] = 9;  //9 means bomb
    //incrementing adjacent cells
    neighbors[1] = cellno-8;
    neighbors[0] = (cellno%8==0)? -1 : cellno-9;
    neighbors[2] = (cellno%8==7)? -1 : cellno-7;
    neighbors[3] = (cellno%8==0)? -1 : cellno-1;
    neighbors[4] = (cellno%8==7)? -1 : cellno+1;
    neighbors[6] = (cellno>55)? -10 : cellno+8;     //cellno>55 -> if cell is in row H
    neighbors[5] = (cellno%8==0)? -1 : cellno+7;
    neighbors[7] = (cellno%8==7)? -1 : cellno+9;
    for(int i=0; i<8;i++){
        if(neighbors[i]<0 || bombs[neighbors[i]]==9) continue;
        bombs[neighbors[i]]++;
    }
}

//open a cell
void open(int cellno){
    if(cellno<0) return;
    if(board[cellno]!='-') return;
    board[cellno] = bombs[cellno]+'0';
    if(bombs[cellno]==0){
        open(cellno-8);
        open((cellno%8==0)? -1 : cellno-9);
        open((cellno%8==7)? -1 : cellno-7);
        open((cellno%8==0)? -1 : cellno-1);
        open((cellno%8==7)? -1 : cellno+1);
        open((cellno>55)? -1 : cellno+8);   //cellno>55 -> if cell is in row H
        open((cellno%8==0)? -1 : cellno+7);
        open((cellno%8==7)? -1 : cellno+9);
    }
    return;
}

//flag cell
//changes board and adds scores
int flag(int cellno){
    board[cellno] = 'F';
    if(bombs[cellno]==9) return 1;
    else return 0;
}

//flag cell
//changes board and subtracts scores
int unflag(int cellno){
    board[cellno] = '-';
    if(bombs[cellno]==9) return -1;
    else return 0;
}

//NOTE: all inputs of cell positions have to be uppercase: A1 B3 C5 E2 F5 G4 G6
int main(){
    char inp[3]={}, move[5]={};             //inp is for input of bombs, move is for moves while playing
    int flags = 0, score=0;                 //amt of flags placed by player and current score
    for(int i=0;i<64;i++) board[i]= '-';    //initialize board to unopened cells "-"
    //input bombs
    for(int i=0;i<7;i++){
        scanf("%s",&inp);
        plant(inp);
    }
    print_bombs();

    //gameplay loop
    while(1){
        int cellno;             //for cell to be opened/flagged
        printf("\nBOARD:\n");
        print_board();
        printf("MOVE: ");

        //input move
        scanf("%c%c%c%c%c", &inp[0],&move[0],&move[1],&move[2],&move[3]);   //some weird C stuff, any other way wont work but its diff in MIPS
        move[4]=0;                                                          //end of move input string
        cellno = ((move[2]-'A')*8) + (move[3]-'1');                         //formula for index in both board arrays

        //move decision | invalid/lost moves HAVE to be decided here, not inside fxns themselves

        //has to be unopened cell
        if(move[0]=='O' && board[cellno]=='-'){
            if(bombs[cellno]==9) break;
            else open(cellno);
        }
        //flags placed cant exceed 7 and cant be flagged/opened already
        else if(move[0]=='F' && flags<7 && board[cellno]=='-'){
            score+= flag(cellno);
            flags++;
        }

        //unflag cell
        else if(move[0]=='U'&& board[cellno]=='F'){
            score+= unflag(cellno);
            flags--;
        }

        //end game
        else if(move[0]=='D') break;

        //default case/invalid input
        else printf("Invalid input\n");
    }
    if(score==7) printf("\nWIN!\n");
    else printf("\nLOSE!\n");
    printf("%d of 7 bombs.\n", score);
    end_game();
    print_board();
    printf("game done");
    return 0;
}