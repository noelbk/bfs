/* Knight's tour bfs solver in C

gcc -Wall -O2 -o knight knight.c
knight 5

2015-10-28 Noel Burton-Krahn <noel@burton-krahn.com>
 */
#include <assert.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>

typedef struct global global_t;
typedef struct board board_t;

typedef unsigned char hit_t;

#define MAX_WIDTH 16
#define MAX_HEIGHT 16

struct global {
    int width;
    int height;
    int moves;
    int used;
    int freed;
    board_t *free;
};

struct board {
    global_t *global;
    board_t *next;
    board_t *prev_move;
    hit_t hits[MAX_WIDTH*MAX_HEIGHT];
    int x, y;
    int moves;
    int ref;
    int done;
};

board_t*
board_ref(board_t *board) {
    if( board ) {
	board->ref++;
    }
    return board;
}

void
board_deref(board_t *board) {
    if( !board || --board->ref > 0 ) {
	return;
    }

    board->ref = 0;
    board->next = 0;
    board_deref(board->prev_move);
    board->prev_move = 0;
    board->next = board->global->free;
    board->global->free = board;
    board->global->freed++;
}

typedef enum {
    GET, SET
} board_hit_op_t;

int
board_hit(board_t *board, int x, int y, board_hit_op_t op) {
    int idx = y*board->global->width+x;
    int ret;

    if( op == SET ) {
	board->x = x;
	board->y = y;
	board->moves++;
	ret = board->hits[idx] = board->moves;
	if( board->moves >= board->global->width * board->global->height ) {
	    board->done = 1;
	}
    }
    else {
	ret = board->hits[idx];
    }
    return ret;
}

board_t*
board_new(int x, int y, board_t *prev_move, board_t *next, global_t *global) {
    board_t *board;
    if( !global && prev_move ) {
	global = prev_move->global;
    }
    if( !global && next ) {
	global = next->global;
    }
    assert(global);
    if( global->free ) {
	board = global->free;
	global->free = global->free->next;
	global->freed--;
    }
    else {
	board = (board_t*)calloc(sizeof(*board), 1);
    }
    global->used++;
    
    if( prev_move ) {
	memcpy(board, prev_move, sizeof(*board));
    }
    else {
	memset(board, 0, sizeof(*board));
    }

    board->global = global;
    board->prev_move = board_ref(prev_move);
    board->next = next;
    board->ref = 1;
    board_hit(board, x, y, SET);
    return board;
}

board_t*
knight_move(board_t *boards) {
    struct move_t {
	int x, y;
    } moves[] = {
	{ 1,  2},
	{ 1, -2},
	{-1,  2},
	{-1, -2},
	{ 2,  1},
	{ 2, -1},
	{-2,  1},
	{-2, -1},
	{0, 0},
    }, *move;
    int done = 0;
    board_t *board, *board_next, *next=0;
    
    while(boards && !done) {
	boards->global->moves++;
	next = 0;
	for(board = boards; board; board = board_next) {
	    board_next = board->next;
	    for(move = moves; move->x; move++) {
		int x = board->x + move->x;
		int y = board->y + move->y;
		if( x>=0 && y>=0
		    && x<board->global->width
		    && y<board->global->height
		    && !board_hit(board, x, y, GET)) {
		    next = board_new(x, y, board, next, 0);
		    if( next->done ) {
			done = 1;
		    }
		}
	    }
	    board_deref(board);
	}
	boards = next;
    }
    return boards;
}

board_t*
knight(global_t *global) {
    int x, y;
    board_t *next = 0;
    global->moves = 1;
    for(y=0; y<=global->height/2; y++) {
	for(x=0; x<=y && x<=global->width/2; x++) {
	    next = board_new(x, y, 0, next, global);
	}
    }
    return knight_move(next);
}

void
board_print(board_t *board) {
    int x, y;
    hit_t *hit = board->hits;
    for(y=0; y<board->global->width; y++) {
	for(x=0; x<board->global->width; x++) {
	    printf(" %2d ", (int)*hit);
	    hit++;
	}
	printf("\n");
    }
    printf("\n");
}

int
main(int argc, char **argv) {
    global_t global;
    board_t *board, *boards;

    int width = 5;
    int height = 5;
    int i, argi = 1;
    char *p;
    
    if( argi < argc ) {
	width = strtoul(argv[argi], &p, 0);
	argi++;
    }
    assert(width>0 && width<MAX_WIDTH);
    if( argi < argc ) {
	height = strtoul(argv[argi], &p, 0);
	argi++;
    }
    else {
	height = width;
    }
    assert(height>0 && height<MAX_HEIGHT);
    
    memset(&global, 0, sizeof(global));
    global.width = width;
    global.height = height;
    boards = knight(&global);
    
    for(board=boards, i=0; board; board=board->next) {
    	if( board->done ) {
	    i++;
	}
    }
    printf("boards=%d\n", i);
    printf("used=%d\n", global.used);
    printf("freed=%d\n", global.freed);
    printf("\n");
	

    for(board=boards; board; board=board->next) {
	if( board->done ) {
	    board_print(board);
	}
    }
    return 0;
}

// Local Variables:
// compile-command: "gcc -Wall -O2 -o knight knight.c"
// End:
