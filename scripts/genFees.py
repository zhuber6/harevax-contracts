import math

def calculate_fees():
    fees = []
    for x in range(15):
        fees.append(150 + 100 * math.pow(math.log10(32), x))
        print(fees[x])

calculate_fees()