import socket


def find_free_port(start_port=8501, max_port=9000):
    """
    Finds a free port starting from start_port up to max_port.
    Returns the first available port.
    """
    for port in range(start_port, max_port + 1):
        with socket.socket(socket.AF_INET, socket.SOCK_STREAM) as s:
            try:
                s.bind(("localhost", port))
                return port
            except OSError:
                continue
    raise RuntimeError("No free port found in range.")


if __name__ == "__main__":
    port = find_free_port()
    print(port)
