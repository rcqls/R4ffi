#ifndef R_FFI_H
#define R_FFI_H

int rffi_init(char* arg); //(int argc,char*  argv[]);
int rffi_eval(char* cmd, int print);
void* rffi_get_ary(char* cmd, int* type, int* len);
double* rffi_as_double_ary(void* res);
int* rffi_as_int_ary(void* res);

#endif