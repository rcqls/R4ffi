/**********************************************************************

  Rffi.c

**********************************************************************/
#include <stdio.h>
#include <string.h>

#include <R.h>
#include <Rembedded.h>
#include <Rinterface.h>
#include <Rinternals.h>
#include <Rdefines.h>
#include <Rversion.h>


/* From Parse.h -- must find better solution: */
#define PARSE_NULL              0
#define PARSE_OK                1
#define PARSE_INCOMPLETE        2
#define PARSE_ERROR             3
#define PARSE_EOF               4


#define Need_Integer(x) (x) = rb_Integer(x)
#define Need_Float(x) (x) = rb_Float(x)
#define Need_Float2(x,y) {\
    Need_Float(x);\
    Need_Float(y);\
}
#define Need_Float3(x,y,z) {\
    Need_Float(x);\
    Need_Float(y);\
    Need_Float(z);\
}

#if (R_VERSION < 132352) /* before 2.5 to check!*/
SEXP R_ParseVector(SEXP, int, int *);
#define RR_ParseVector(x,y,z) R_ParseVector(x, y, z)
#else
SEXP R_ParseVector(SEXP, int, int *,SEXP);
#define RR_ParseVector(x,y,z) R_ParseVector(x, y, z, R_NilValue)
#endif

/************* INIT *********************/

extern Rboolean R_Interactive;
extern uintptr_t R_CStackLimit; /* C stack limit */
extern uintptr_t R_CStackStart; /* Initial stack address */
//extern int Rf_initEmbeddedR(int argc, char *argv[]);

int rffi_init(char* arg) //(int argc,char* argv[])
{
  char* argv[4];
  argv[0]="REmbed";
  argv[1]="--save";
  argv[2]="--slave";
  argv[3]="--quiet";
  R_CStackStart = (uintptr_t)-1;
  Rf_initEmbeddedR(4,argv);
  R_Interactive = FALSE;
  return 1;
}

/***************** EVAL **********************/

int rffi_eval(char* cmds, int print)
{
  int nbCmds,errorOccurred,status, i;

  SEXP text, expr, ans=R_NilValue /* -Wall */;


  //printf("Avant parsing\n");

  nbCmds=1;

  //printf("nbCmds : %d\n",nbCmds);

  text = PROTECT(allocVector(STRSXP, nbCmds));
  for (i = 0 ; i < nbCmds ; i++) {
    SET_STRING_ELT(text, i, mkChar(cmds));
  }
  expr = PROTECT(RR_ParseVector(text, -1, &status));

  if (status != PARSE_OK) {
    //printf("Parsing error (status=%d) in:\n",status);
    for (i = 0 ; i < nbCmds ; i++) {
      //printf("%s\n",cmds);
    }
    UNPROTECT(2);
    return 0;
  }
  
  /* Note that expr becomes an EXPRSXP and hence we need the loop
     below (a straight eval(expr, R_GlobalEnv) won't work) */
  {
    for(i = 0 ; i < nbCmds ; i++)
      ans = R_tryEval(VECTOR_ELT(expr, i),NULL, &errorOccurred);
      if(errorOccurred) {
        //fprintf(stderr, "Caught another error calling sqrt()\n");
        fflush(stderr);
        UNPROTECT(2);
        return 0;
      }

      if (print) {
        Rf_PrintValue(ans);
      }
  }

  UNPROTECT(2);
  return 1;
}

//array 
void* util_SEXP2C(SEXP ans,int* type,int* len) {
  *len=length(ans);
  void* res;
  switch(TYPEOF(ans)) {
  case REALSXP:
    *type=0;
    //printf("type is real\n");
    res=(void*)(REAL(ans));
    break;
  case INTSXP:
    *type=1;
    res=(void*)(INTEGER(ans));
    break;
  case LGLSXP:
    *type=2;
    res=(void*)(INTEGER(ans));
    break;
  // case STRSXP:
  //   for(i=0;i<n;i++) {
  //     rb_ary_store(res,i,rb_str_new2(CHAR(STRING_ELT(ans,i))));
  //   }
  //   break;
  // case CPLXSXP:
  //   rb_require("complex");
  //   for(i=0;i<n;i++) {
  //     Rcomplex cpl=COMPLEX(ans)[i];
  //     res2 = rb_eval_string("Complex.new(0,0)");
  //     rb_iv_set(res2,"@real",rb_float_new(cpl.r));
  //     rb_iv_set(res2,"@image",rb_float_new(cpl.i));
  //     rb_ary_store(res,i,res2);
  //   }
  //   break;
  }

  return res;
}

// 
void* rffi_get_ary(char* cmd,int* type,int* len) {
  int  errorOccurred,status, i;
    
  SEXP text, expr, ans; //=R_NilValue /* -Wall */;

  text = PROTECT(allocVector(STRSXP, 1)); 
//printf("cmd: %s\n",cmdString);
  SET_STRING_ELT(text, 0, mkChar(cmd));
  expr = PROTECT(RR_ParseVector(text, -1, &status));
  if (status != PARSE_OK) {
    printf("Parsing error in: %s\n",cmd);
    UNPROTECT(2);
    return (void*)NULL;
  }
  /* Note that expr becomes an EXPRSXP and hence we need the loop
     below (a straight eval(expr, R_GlobalEnv) won't work) */
  ans = R_tryEval(VECTOR_ELT(expr, 0),R_GlobalEnv,&errorOccurred);
  if(errorOccurred) {
    //fflush(stderr);
    printf("Exec error in: %s\n",cmd);
    UNPROTECT(2);
    return (void*)NULL;
  }
  UNPROTECT(2);
  //printf("eval_get\n");
  return util_SEXP2C(ans,type,len);
}

double* rffi_as_double_ary(void* res) {
   return (double*)res;
}

int* rffi_as_int_ary(void* res) {
   return (int*)res;
}

SEXP util_C2SEXP(void* arr,int type,int n) {
  SEXP ans;
  int i; 
  
  if(type==0) {
    PROTECT(ans=allocVector(REALSXP,n));
    for(i=0;i<n;i++) {
      REAL(ans)[i]=((double*)arr)[i];
    }
    UNPROTECT(1);
  } else if(type==1) {
    PROTECT(ans=allocVector(INTSXP,n));
    for(i=0;i<n;i++) {
      INTEGER(ans)[i]=((int*)arr)[i];
    }
    UNPROTECT(1);
  } else if(type==2) {
    PROTECT(ans=allocVector(LGLSXP,n));
    for(i=0;i<n;i++) {
      LOGICAL(ans)[i]=((int*)arr)[i];
    }
    UNPROTECT(1);
  } else ans=R_NilValue;

  return ans; 
}

void rffi_set_ary(char* name,void* arr,int type,int len) {
  SEXP ans=util_C2SEXP(arr,type,len);
  defineVar(install(name),ans,R_GlobalEnv);
}

//because of node-ffi!

void rffi_set_int_ary(char* name,int* arr,int len) {
  SEXP ans=util_C2SEXP((void*)arr,1,len);
  defineVar(install(name),ans,R_GlobalEnv);
}

void rffi_set_double_ary(char* name,double* arr,int len) {
  SEXP ans=util_C2SEXP((void*)arr,0,len);
  defineVar(install(name),ans,R_GlobalEnv);
}

void rffi_set_logical_ary(char* name,int* arr,int len) {
  SEXP ans=util_C2SEXP((void*)arr,2,len);
  defineVar(install(name),ans,R_GlobalEnv);
}

// double* rffi_get_double(char* cmd,int* len) {
//    int type;
//    void* res=rffi_get_ary(cmd,&type,len);
//    return rffi_as_double_ary(res);
// }

// int* rffi_get_int(char* cmd,int* len) {
//    int type;
//    void* res=rffi_get_ary(cmd,&type,len);
//    return rffi_as_int_ary(res);
// }

// double* rffi_get_double(char* cmd,int* len)
// {
//   int  errorOccurred,status, i;
    
//   SEXP text, expr, ans; //=R_NilValue /* -Wall */;

//   text = PROTECT(allocVector(STRSXP, 1)); 
// //printf("cmd: %s\n",cmdString);
//   SET_STRING_ELT(text, 0, mkChar(cmd));
//   expr = PROTECT(RR_ParseVector(text, -1, &status));
//   if (status != PARSE_OK) {
//     printf("Parsing error in: %s\n",cmd);
//     UNPROTECT(2);
//     return (double*)NULL;
//   }
//   /* Note that expr becomes an EXPRSXP and hence we need the loop
//      below (a straight eval(expr, R_GlobalEnv) won't work) */
//   ans = R_tryEval(VECTOR_ELT(expr, 0),R_GlobalEnv,&errorOccurred);
//   if(errorOccurred) {
//     //fflush(stderr);
//     printf("Exec error in: %s\n",cmd);
//     UNPROTECT(2);
//     return (double*)NULL;
//   }
//   UNPROTECT(2);
//   //printf("eval_get\n");
//   *len=length(ans);
//   return REAL(ans);
// }

// /***************** PARSE **********************/

// VALUE R2rb_parse(VALUE obj, VALUE cmd,VALUE print)
// {
//   char *cmdString;
//   int nbCmds;
//   VALUE tmp;
//   int status,i;

//   SEXP text, expr, ans=R_NilValue /* -Wall */;


//   //printf("Avant parsing\n");

//   nbCmds=RARRAY_LEN(cmd);

//   //printf("nbCmds : %d\n",nbCmds);

//   text = PROTECT(allocVector(STRSXP, nbCmds));
//   for (i = 0 ; i < nbCmds ; i++) {
//     tmp=rb_ary_entry(cmd,i);
//     cmdString=StringValuePtr(tmp);
//     SET_STRING_ELT(text, i, mkChar(cmdString));
//   }
//   expr = PROTECT(RR_ParseVector(text, -1, &status));

//   if (status != PARSE_OK) {
//     if (print != Qnil) printf("Parsing error (status=%d) in:\n",status);
//     for (i = 0 ; i < nbCmds ; i++) {
//       tmp=rb_ary_entry(cmd,i);
//       cmdString=StringValuePtr(tmp);
//       if (print != Qnil) printf("%s\n",cmdString);
//     }
//     //UNPROTECT(2);
//     //return Qfalse;
//   }
//   UNPROTECT(2);
//   //return Qtrue;
//   return INT2FIX(status);
// }


// /*****************************************

// Interface to get values of RObj from Ruby
// The basic idea : no copy of the R Vector
// just methods to extract value !!!

// ******************************************/

// // used internally !!! -> eval only one string line
// SEXP util_eval1string(VALUE cmd)
// {
//   char *cmdString;
//   int  errorOccurred,status, i;
    
//   SEXP text, expr, ans=R_NilValue /* -Wall */;

//   text = PROTECT(allocVector(STRSXP, 1)); 
//   cmdString=StringValuePtr(cmd);
// //printf("cmd: %s\n",cmdString);
//   SET_STRING_ELT(text, 0, mkChar(cmdString));
//   expr = PROTECT(RR_ParseVector(text, -1, &status));
//   if (status != PARSE_OK) {
//     printf("Parsing error in: %s\n",cmdString);
//     UNPROTECT(2);
//     return R_NilValue;
//   }
//   /* Note that expr becomes an EXPRSXP and hence we need the loop
//      below (a straight eval(expr, R_GlobalEnv) won't work) */
//   ans = R_tryEval(VECTOR_ELT(expr, 0),R_GlobalEnv,&errorOccurred);
//   //ans = eval(VECTOR_ELT(expr, 0),R_GlobalEnv);
//   if(errorOccurred) {
//     //fflush(stderr);
//     printf("Exec error in: %s\n",cmdString);
//     UNPROTECT(2);
//     return R_NilValue;
//   }
//   UNPROTECT(2);
//   return ans;
// }

// int util_isVector(SEXP ans)
// {
//   return (!isNewList(ans) & isVector(ans));
// }

// int util_isVariable(VALUE self)
// {
//   VALUE tmp;
//   tmp=rb_iv_get(self,"@type");
//   return strcmp(StringValuePtr(tmp),"var")==0;
// }

// SEXP util_getVar(VALUE self)
// {
//   SEXP ans;
//   char *name;
//   VALUE tmp;

//   tmp=rb_iv_get(self,"@name");
//   name=StringValuePtr(tmp);
//   if(util_isVariable(self)) {
//     ans = findVar(install(name),R_GlobalEnv); //currently in  R_GlobalEnv!!!
//   } else {
//     //printf("getVar:%s\n",name);
//     ans=util_eval1string(rb_iv_get(self,"@name"));
//     if(ans==R_NilValue) return ans;
//   }
//   if(!util_isVector(ans)) return R_NilValue;
//   return ans;
// }

// //with argument!! necessarily an expression and not a variable
// SEXP util_getExpr_with_arg(VALUE self)
// {
//   SEXP ans;
//   VALUE tmp;

//   //printf("getVar:%s\n",name);
//   tmp=rb_str_dup(rb_iv_get(self,"@arg"));
//   ans=util_eval1string(rb_str_cat2(rb_str_dup(rb_iv_get(self,"@name")),StringValuePtr(tmp)));
//   if(ans==R_NilValue) return ans;
//   if(!util_isVector(ans)) return R_NilValue;
//   return ans;
// }


// VALUE util_SEXP2VALUE(SEXP ans)
// {
//   VALUE res;
//   int n,i;
//   Rcomplex cpl;
//   VALUE res2; 
  
//   n=length(ans);
//   res = rb_ary_new2(n);
//   switch(TYPEOF(ans)) {
//   case REALSXP:
//     for(i=0;i<n;i++) {
//       rb_ary_store(res,i,rb_float_new(REAL(ans)[i]));
//     }
//     break;
//   case INTSXP:
//     for(i=0;i<n;i++) {
//       rb_ary_store(res,i,INT2FIX(INTEGER(ans)[i]));
//     }
//     break;
//   case LGLSXP:
//     for(i=0;i<n;i++) {
//       rb_ary_store(res,i,(INTEGER(ans)[i] ? Qtrue : Qfalse));
//     }
//     break;
//   case STRSXP:
//     for(i=0;i<n;i++) {
//       rb_ary_store(res,i,rb_str_new2(CHAR(STRING_ELT(ans,i))));
//     }
//     break;
//   case CPLXSXP:
//     rb_require("complex");
//     for(i=0;i<n;i++) {
//       cpl=COMPLEX(ans)[i];
//       res2 = rb_eval_string("Complex.new(0,0)");
//       rb_iv_set(res2,"@real",rb_float_new(cpl.r));
//       rb_iv_set(res2,"@image",rb_float_new(cpl.i));
//       rb_ary_store(res,i,res2);
//     }
//     break;
//   }

//   return res;
// }


// SEXP util_VALUE2SEXP(VALUE arr)
// {
//   SEXP ans;
//   VALUE res,class,tmp;
//   int i,n=0;

//   if(!rb_obj_is_kind_of(arr,rb_cArray)) {
//     n=1;
//     res = rb_ary_new2(1);
//     rb_ary_push(res,arr);
//     arr=res;
//   } else {
//     n=RARRAY_LEN(arr);
//   }  

//   class=rb_class_of(rb_ary_entry(arr,0));
  
//   if(class==rb_cFloat) {
//     PROTECT(ans=allocVector(REALSXP,n));
//     for(i=0;i<n;i++) {
//       REAL(ans)[i]=NUM2DBL(rb_ary_entry(arr,i));
//     }
//   } else if(class==rb_cFixnum || class==rb_cBignum) {
//     PROTECT(ans=allocVector(INTSXP,n));
//     for(i=0;i<n;i++) {
//       INTEGER(ans)[i]=NUM2INT(rb_ary_entry(arr,i));
//     }
//   } else if(class==rb_cTrueClass || class==rb_cFalseClass) {
//     PROTECT(ans=allocVector(LGLSXP,n));
//     for(i=0;i<n;i++) {
//       LOGICAL(ans)[i]=(rb_class_of(rb_ary_entry(arr,i))==rb_cFalseClass ? FALSE : TRUE);
//     }
//   } else if(class==rb_cString) {
//     PROTECT(ans=allocVector(STRSXP,n));
//     for(i=0;i<n;i++) {
//       tmp=rb_ary_entry(arr,i);
//       SET_STRING_ELT(ans,i,mkChar(StringValuePtr(tmp)));
//     }
//   } else ans=R_NilValue;

//   if(n>0) UNPROTECT(1);
//   return ans; 
// }



// VALUE RVect_initialize(VALUE self, VALUE name)
// {
//   rb_iv_set(self,"@name",name);
//   rb_iv_set(self,"@type",rb_str_new2("var"));
//   rb_iv_set(self,"@arg",rb_str_new2(""));
//   return self;
// }

// VALUE RVect_isValid(VALUE self)
// {
//   SEXP ans;
//   char *name;

// #ifdef cqls
//   VALUE tmp;
//   tmp=rb_iv_get(self,"@name");
//   name = StringValuePtr(tmp);
//   ans = findVar(install(name),R_GlobalEnv); //currently in  R_GlobalEnv!!!
// #else
//   ans = util_getVar(self);
// #endif
//   if(!util_isVector(ans)) {
//     rb_warn("%s is not a R vector !!!",name);
//     return Qfalse;
//   }
//   return Qtrue;
// }

// VALUE RVect_length(VALUE self)
// {
//   SEXP ans;
//   char *name;
// #ifdef cqls
//   VALUE tmp;
//   tmp=rb_iv_get(self,"@name");
//   if(!RVect_isValid(self)) return Qnil;
//   name = StringValuePtr(tmp);
//   ans = findVar(install(name),R_GlobalEnv); //currently in  R_GlobalEnv!!!
// #else
//   ans = util_getVar(self);

//   if(ans==R_NilValue) {
//     //printf("Sortie de length avec nil\n");
//     return Qnil;
//   }
// #endif
//   return INT2NUM(length(ans));
// }

// VALUE RVect_get(VALUE self)
// {
//   SEXP ans;
//   VALUE res;
//   char *name;
//   int n,i;
//   Rcomplex cpl;
//   VALUE res2; 

//   //#define cqls
// #ifdef cqls 
//   VALUE tmp;
//   if(!RVect_isValid(self)) return Qnil;
// #else  
//   ans = util_getVar(self);

//   if(ans==R_NilValue) {
//     //printf("Sortie de get avec nil\n");
//     return Qnil;
//   }
// #endif
// #ifdef cqls 
//   tmp=rb_iv_get(self,"@name");
//   name = StringValuePtr(tmp);
//   ans = findVar(install(name),R_GlobalEnv); 
// #endif

//   res=util_SEXP2VALUE(ans);
//   if(length(ans)==1) res=rb_ary_entry(res,0);
//   return res; 
// }

// VALUE RVect_get_with_arg(VALUE self)
// {
//   SEXP ans;
//   VALUE res;
//   char *name;
//   int n,i;
//   Rcomplex cpl;
//   VALUE res2; 

//   ans = util_getExpr_with_arg(self);
 
//   if(ans==R_NilValue) {
//     //printf("Sortie de get avec nil\n");
//     return Qnil;
//   }
//   res=util_SEXP2VALUE(ans);
 
// //printf("RVect_get_with_arg: length(ans)=%d\n",length(ans));
//  if (length(ans)==1) res=rb_ary_entry(res,0);

//   return res;
// }



// // faster than self.to_a[index]
// VALUE RVect_aref(VALUE self, VALUE index)
// {
//   SEXP ans;
//   VALUE res;
//   char *name;
//   int n,i;
//   Rcomplex cpl;
// #ifdef cqls
//   VALUE tmp;
// #endif
//   i = FIX2INT(index);
  
// #ifdef cqls
//   if(!RVect_isValid(self)) return Qnil;
//   tmp=rb_iv_get(self,"@name");
//   name = StringValuePtr(tmp);
//   ans = findVar(install(name),R_GlobalEnv); //currently in  R_GlobalEnv!!!
// #else
//   ans = util_getVar(self);
// #endif
//   n=length(ans);
//   //printf("i=%d and n=%d\n",i,n);
//   if(i<n) {
//     switch(TYPEOF(ans)) {
//     case REALSXP:
//       res=rb_float_new(REAL(ans)[i]);
//       break;
//     case INTSXP:
//       res=INT2FIX(INTEGER(ans)[i]);
//       break;
//     case LGLSXP:
//       res=(INTEGER(ans)[i] ? Qtrue : Qfalse);
//       break;
//     case STRSXP:
//       res=rb_str_new2(CHAR(STRING_ELT(ans,i)));
//       break;
//     case CPLXSXP:
//       rb_require("complex");
//       cpl=COMPLEX(ans)[i];
//       res = rb_eval_string("Complex.new(0,0)");
//       rb_iv_set(res,"@real",rb_float_new(cpl.r));
//       rb_iv_set(res,"@image",rb_float_new(cpl.i));
//       break;
//     }
//   } else {
//     res = Qnil;
//   }
//   return res;
// }

// VALUE RVect_set(VALUE self,VALUE arr)
// {
//   SEXP ans;
//   char *name;
//   VALUE tmp;

//   ans=util_VALUE2SEXP(arr);
  
//   tmp=rb_iv_get(self,"@name");
//   name = StringValuePtr(tmp);
//   if(util_isVariable(self)) {
//     defineVar(install(name),ans,R_GlobalEnv); //currently in R_GlobalEnv!!!
//   } else {
//     defineVar(install(".rubyExport"),ans,R_GlobalEnv);
//     util_eval1string(rb_str_cat2(rb_str_dup(rb_iv_get(self,"@name")),"<-.rubyExport"));
//   }

//   return self; 
// }

// VALUE RVect_assign(VALUE obj, VALUE name,VALUE arr)
// {
//   SEXP ans;
//   char *tmp;

//   ans=util_VALUE2SEXP(arr);

//   tmp = StringValuePtr(name);
//   defineVar(install(tmp),ans,R_GlobalEnv);

//   return Qnil; 
// }

// VALUE RVect_set_with_arg(VALUE self,VALUE arr)
// {
//   VALUE tmp;
//   defineVar(install(".rubyExport"),util_VALUE2SEXP(arr),R_GlobalEnv);
//   tmp=rb_iv_get(self,"@arg"); 
//   util_eval1string(rb_str_cat2(rb_str_cat2(rb_str_dup(rb_iv_get(self,"@name")),StringValuePtr(tmp)),"<-.rubyExport"));
//   return self;
// }
