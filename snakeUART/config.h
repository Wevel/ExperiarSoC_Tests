#define CPU_FREQUENCY 40000000 // Hz
#define CPU_CLOCK_PERIOD (1000000000 / CPU_FREQUENCY) // ns

#define UART1_ENABLE
#define UART1_BAUD_RATE 9216000 // This is way too high to actually used, but need so simulation doesn't take forever

#define USE_UART_INPUT 1
#define USE_UART_OUTPUT 1
#define USER_UART_INTERRUPT 0

#define MAP_WIDTH 16
#define MAP_HEIGHT 12
#define MAX_TAIL_LENGTH 64

#define MAP_SIZE (MAP_WIDTH * MAP_HEIGHT)

#define MOVE_TIMEOUT 100 // us