import os 
import random
import string
import sys
import numpy



def generate_random_data_for_4_4_systolic_array(a_size=(4,4),b_size=(4,4), c_size=(4,4), data_bitwdith=3, num_test=4):
    """
    This function generates random data for a 4x4 systolic array doing 4x4 matrix multiplication
    C = A * B
    """

    if a_size[0] != c_size[0] or b_size[1] != c_size[1] or a_size[1] != b_size[0]:
        raise ValueError(f"Improper matrix dimensions: {a_size}, {b_size}, {c_size}")

    a_matrix_list = []
    b_matrix_list = []
    c_matrix_list = []
    for _ in range(num_test):
        #generate a random a matrix
        a_matrix = numpy.random.randint(1, 2 ** data_bitwdith, size=a_size)
        b_matrix = numpy.random.randint(1, 2 ** data_bitwdith, size=b_size)
        #c = numpy.matmul(a_matrix, b_matrix)
        c_matrix = numpy.matmul(a_matrix, b_matrix)
        a_matrix_list.append(a_matrix)
        b_matrix_list.append(b_matrix)
        c_matrix_list.append(c_matrix)
    a_matrix_merged = numpy.concatenate(a_matrix_list, axis=1)
    b_matrix_merged = numpy.concatenate(b_matrix_list, axis=0)
    c_matrix_merged = numpy.concatenate(c_matrix_list, axis=1)

    K_direction = max(a_size[1] * num_test + a_size[0], b_size[0] * num_test + b_size[1])
    #shift the row of a matrix each by row_idx, and zero pad the front and back
    a_matrix_shifted = numpy.zeros((a_size[0], K_direction))
    for row_idx in range(a_size[0]):
        a_matrix_shifted[row_idx, row_idx : row_idx + a_size[1] * num_test] = a_matrix_merged[row_idx, :]
    
    b_matrix_shifted = numpy.zeros((K_direction, b_size[1]))
    for col_idx in range(b_size[1]):
        b_matrix_shifted[col_idx : col_idx + b_size[0] * num_test, col_idx] = b_matrix_merged[:, col_idx]
    
    c_matrix_shifted = numpy.zeros((c_size[0], c_size[1] * num_test + c_size[0] - 1))
    for row_idx in range(c_size[0]):
        c_matrix_shifted[row_idx][row_idx:row_idx+c_size[1]*num_test] = c_matrix_merged[row_idx]
    
    a_matrix_shifted = a_matrix_shifted.astype(numpy.uint8)
    b_matrix_shifted = b_matrix_shifted.astype(numpy.uint8)
    c_matrix_shifted = c_matrix_shifted.astype(numpy.uint8)
    d_matrix = c_matrix_merged.astype(numpy.uint8)


    #store transposed a matrix and b matrix 
    a_matrix_shifted.T.tofile("a_matrix.bin")
    b_matrix_shifted.tofile("b_matrix.bin")
    c_matrix_shifted.T.tofile("c_matrix.bin")
    d_matrix.T.tofile("d_matrix.bin")

    print("A matrix: ")
    print(a_matrix_shifted.T)
    print("B matrix: ")
    print(b_matrix_shifted)
    print("C matrix: ")
    print(c_matrix_shifted.T)

    print("A matrix combined hex string: ")
    for row in a_matrix_shifted.T:
        print("".join(["{:02x}".format(x) for x in row]))
    print("B matrix combined hex string: ")
    for row in b_matrix_shifted:
        print("".join(["{:02x}".format(x) for x in row]))
    print("C matrix combined hex string: ")
    for row in c_matrix_shifted.T:
        print("".join(["{:02x}".format(x) for x in row]))


def verify_results(
        gold_data_file, 
        result_data_file, 
        a_matrix_file="a_matrix.bin", 
        b_matrix_file="b_matrix.bin",
        row_size=4,
        col_size=4,
        k_size=4,
        num_tests=1
    ):
    """
    This function verifies the results of the systolic array
    """
    # Dump some logs
    numpy.set_printoptions(threshold=numpy.inf, linewidth=numpy.inf)
    a_matrix = numpy.fromfile(a_matrix_file, dtype=numpy.uint8)
    b_matrix = numpy.fromfile(b_matrix_file, dtype=numpy.uint8)
    log_gold = numpy.fromfile(gold_data_file, dtype=numpy.uint8)
    log_result = numpy.fromfile(result_data_file, dtype=numpy.uint8)

    #print(log_gold)
    #print(log_result)

    # b_size_0, b_size_1 = b_matrix.shape[0] // col_size, col_size
    # a_size_0 = a_matrix.shape[0] // b_size_0
    # a_size_1 = a_matrix.shape[0] // a_size_0
    c_size_0, c_size_1 = log_gold.shape[0] // row_size, row_size

    a_size_0, a_size_1 = row_size, k_size * num_tests + row_size
    b_size_0, b_size_1 = k_size * num_tests + col_size, col_size
    # c_size_0, c_size_1 = col_size * num_tests, row_size

    K_direction = max(a_size_1, b_size_0)

    a_matrix = numpy.reshape(a_matrix, (K_direction, a_size_0))
    b_matrix = numpy.reshape(b_matrix, (K_direction, b_size_1))
    log_gold = numpy.reshape(log_gold, (c_size_0, c_size_1))
    log_result = numpy.reshape(log_result, (len(log_result)//row_size, row_size))

    print(f"Matrix A:\n{a_matrix}\n")
    print(f"Matrix B:\n{b_matrix}\n")
    print(f"Gold: \n{log_gold}\n")
    print(f"Result: \n{log_result}\n")


    gold_data = numpy.fromfile(gold_data_file, dtype=numpy.uint8)
    result_data = numpy.fromfile(result_data_file, dtype=numpy.uint8)
    #reshape into a col_size of 4, unknown row size
    gold_data = gold_data.reshape(-1, row_size)
    result_data = result_data.reshape(-1, row_size)
    print("Gold data shape: ", gold_data.shape)
    print("Result data shape: ", result_data.shape)

    #1st row of gold data as start indicator
    start_indicator = gold_data[0]
    #last row of gold data as end indicator
    end_indicator = gold_data[-1]
    print("Start indicator for outputing results: ", start_indicator)
    print("End indicator for outputing results: ", end_indicator)
    
    #find the start indicator in result data
    start_indicator_idx = -1
    for row_idx in range(result_data.shape[0]):
        if numpy.array_equal(result_data[row_idx], start_indicator):
            start_indicator_idx = row_idx
            break
    print("Start indicator idx: ", start_indicator_idx)
    #if the start indicator is not found, return false
    if start_indicator_idx == -1:
        return False
    #find the end indicator in result data
    end_indicator_idx = -1
    for row_idx in range(result_data.shape[0]-1, 0, -1):
        if numpy.array_equal(result_data[row_idx], end_indicator):
            end_indicator_idx = row_idx
            break
    #if the end indicator is not found, return false
    if end_indicator_idx == -1:
        return False
    print("End indicator idx: ", end_indicator_idx)
    #take the data in between start and end indicator
    result_data = result_data[start_indicator_idx:end_indicator_idx+1]

    #compare the data
    if numpy.array_equal(gold_data, result_data):
        print(True)
        return True
    else:
        return False
    





if __name__ == "__main__":
    import argparse

    #take in the command line arguments
    parser = argparse.ArgumentParser()
    # mode = str(sys.argv[1])
    parser.add_argument("--mode", type=str, default='gen_data', help="Mode to run the script")
    parser.add_argument("--a-size", type=str, default="4x4", help="matrix A dimensions")
    parser.add_argument("--b-size", type=str, default="4x4", help="Matrix B dimensions")
    parser.add_argument("--c-size", type=str, default="4x4", help="Matrix C dimensions")
    parser.add_argument("--num-tests", type=int, default=1, help="Number of tests to generate")
    parser.add_argument('--seed', default=1, type=int, help="Random seed")
    args = parser.parse_args()

    numpy.random.seed(args.seed)
    
    a_size = args.a_size.split("x")
    a_size = (int(a_size[0]), int(a_size[1]))
    
    b_size = args.b_size.split("x")
    b_size = (int(b_size[0]), int(b_size[1]))
    
    c_size = args.c_size.split("x")
    c_size = (int(c_size[0]), int(c_size[1]))
    
    if args.mode == "gen_data":
        # generate_random_data_for_4_4_systolic_array(num_test=num_test)
        generate_random_data_for_4_4_systolic_array(a_size=a_size, b_size=b_size, c_size=c_size, num_test=args.num_tests)
    else:
        # result = verify_results("c_matrix.bin", "results.bin")
        result = verify_results("c_matrix.bin", "results.bin", row_size=a_size[0], col_size=c_size[1], k_size=a_size[1], num_tests=args.num_tests)
        if result:
            print("PASSED!")
        else:
            print("FAILED!")
