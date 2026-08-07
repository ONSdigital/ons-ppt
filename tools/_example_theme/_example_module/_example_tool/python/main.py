"""
Tool Name: Example Adder Tool
Description: Adds two numbers together and prints the result.
"""


def add_numbers(x: float, y: float) -> float:
    """
    Adds two numbers together.

    Args:
        x (float): First number.
        y (float): Second number.

    Returns:
        float: The sum of x and y.
    """
    return x + y


if __name__ == "__main__":
    print(add_numbers(2, 3))
