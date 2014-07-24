#include <R2rb.h>

int main(int argc, char** argv)
{
	r2rb_init("--save --slave --quiet");
	
	r2rb_eval("rnorm(10)", 1);
	return 0;
}