#! /usr/bin/python
# 
# solve n-queens breadth-first
#
# 2015-10-28 Noel Burton-Krahn <noel@burton-krahn.com>



def queens(n):
    solutions = [[]]
    for row in range(n):
        sol_next = []
        for queens in solutions:
            for col in range(n):
                if not attacked(queens, row, col):
                    sol_next.append(queens + [col])
        solutions = sol_next
    return solutions

def attacked(queens, row, col):
    for queen_row, queen_col in enumerate(queens):
        if (queen_col == col
            or queen_row - queen_col == row - col
            or queen_row + queen_col == row + col):
            return True
    return False
            
def board(queens):
    s = ""
    n = len(queens)
    for row in range(n):
        for col in range(n):
            c = '.'
            if col == queens[row]:
                c = 'Q'
            s += c
        s += '\n'
    return s

if __name__ == '__main__':
    import sys
    n = 8
    if len(sys.argv)>1:
        n = int(sys.argv[1])
    for q in queens(n):
        print board(q)
        print
    
