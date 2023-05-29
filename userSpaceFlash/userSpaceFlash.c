#include <stdint.h>

volatile uint32_t state = 0;
volatile uint32_t primaryTotal = 0;
volatile uint32_t secondaryTotal = 0;

const char paddingBuffer[] = "Lorem ipsum dolor sit amet, consectetur adipiscing elit. Aenean quis tellus quis justo egestas eleifend. In nec magna nisl. Integer tincidunt nisl vitae nisl blandit maximus. Cras at nibh dui. Proin rutrum tincidunt nibh in egestas. Vivamus ornare ultrices mi. Nullam ac semper lectus. Orci varius natoque penatibus et magnis dis parturient montes, nascetur ridiculus mus. Integer aliquet vitae arcu eget bibendum. Suspendisse varius diam at ex feugiat semper. Duis bibendum volutpat leo, ut suscipit leo laoreet bibendum. Etiam id tincidunt libero. Proin odio leo, aliquet in leo quis, aliquam varius orci. Praesent sed semper arcu. Donec nec volutpat neque, a dapibus tortor. Pellentesque massa libero, rutrum nec suscipit in, tincidunt eget justo. Cras ullamcorper, lorem nec lacinia condimentum, nunc justo cursus arcu, eu vulputate leo mi dictum arcu. Vivamus imperdiet sapien sem, semper scelerisque odio finibus in. Nunc vestibulum gravida tellus eu elementum. Interdum et malesuada fames ac ante ipsum primis bi.";
const char paddingBuffer2[] __attribute__ ((section (".page2.paddingBuffer2"))) = "Lorem ipsum dolor sit amet, consectetur adipiscing elit. Aenean quis tellus quis justo egestas eleifend. In nec magna nisl. Integer tincidunt nisl vitae nisl blandit maximus. Cras at nibh dui. Proin rutrum tincidunt nibh in egestas. Vivamus ornare ultrices mi. Nullam ac semper lectus. Orci varius natoque penatibus et magnis dis parturient montes, nascetur ridiculus mus. Integer aliquet vitae arcu eget bibendum. Suspendisse varius diam at ex feugiat semper. Duis bibendum volutpat leo, ut suscipit leo laoreet bibendum. Etiam id tincidunt libero. Proin odio leo, aliquet in leo quis, aliquam varius orci. Praesent sed semper arcu. Donec nec volutpat neque, a dapibus tortor. Pellentesque massa libero, rutrum nec suscipit in, tincidunt eget justo. Cras ullamcorper, lorem nec lacinia condimentum, nunc justo cursus arcu, eu vulputate leo mi dictum arcu. Vivamus imperdiet sapien sem, semper scelerisque odio finibus in. Nunc vestibulum gravida tellus eu elementum. Interdum et malesuada fames ac ante ipsum primis bi.";
volatile char currentChar = 0;

void primaryLoop ();
void secondaryLoop ();

void main ()
{
	primaryLoop ();
}

void primaryLoop ()
{
	uint32_t i = 0;
	while (1)
	{
		if (state == 0)
		{
			currentChar = paddingBuffer[i % sizeof (paddingBuffer)];
			primaryTotal += i * i;
			i += 1;
		}
		else
		{
			secondaryLoop ();
			break;
		}
	}
}

__attribute__ ((section (".page2.secondaryLoop"))) uint32_t page2Mod (uint32_t a, uint32_t b)
{
	while (a > b) a -= b;
	return a;
}

__attribute__ ((section (".page2.secondaryLoop"))) void secondaryLoop ()
{
	uint32_t i = 0;
	while (1)
	{
		if (state == 1)
		{
			currentChar = paddingBuffer2[page2Mod (i + (sizeof (paddingBuffer2) / 2), sizeof (paddingBuffer2))];
			secondaryTotal += i;
			i += 1;
		}
		else
		{
			primaryLoop ();
			break;
		}
	}
}