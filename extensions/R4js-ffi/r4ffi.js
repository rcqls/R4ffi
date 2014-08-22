var ref=require("ref");
var RefArray = require('ref-array');
var ffi=require("ffi");

var intPtr=ref.refType("int");
var voidPtr=ref.refType("void");
var doubleAry=RefArray("double");
//var VoidArray=RefArray("void");
var intAry=RefArray("int");
var stringAry=RefArray("string");

var rffi=ffi.Library(process.env["R4FFI_LIB"] || "/Users/remy/devel/R4ffi/build/lib/libRffi.dylib",{
	"rffi_init":["int",["string"]],
	"rffi_eval":["int",["string","int"]],
	"rffi_get_ary":[voidPtr,["string",intPtr,intPtr]],
	"rffi_as_double_ary":[doubleAry,[voidPtr]],
	"rffi_as_int_ary":[intAry,[voidPtr]],
	"rffi_as_string_ary":[stringAry,[voidPtr]],
	"rffi_set_ary":["void",["string","pointer","int","int"]]
})

var intPtr=ref.refType(ref.types.int);

var init=function() {
	rffi.rffi_init("--save");
}

var eval=function(cmd) {
	rffi.rffi_eval(cmd,1);
}

var exec=function(cmd) {
	rffi.rffi_eval(cmd,0);
}

var get_int=function(varname) {
	var l=ref.alloc("int");
	var res=rffi.rffi_get_int(varname,l);
	var l=ref.deref(l);
	//console.log("l=",l,"\n");
	res.length=l;
	return(res);
}

var get_double=function(varname) {
	var l=ref.alloc("int");
	var res=rffi.rffi_get_double(varname,l);
	var l=ref.deref(l);
	//console.log("l=",l,"\n");
	res.length=l;
	return(res);
}

var get_ary=function(cmd) {
	var t=ref.alloc("int");
	var l=ref.alloc("int")
	var res=rffi.rffi_get_ary(cmd,t,l);
	if(res.isNull()) console.log("res null");
	var t=ref.deref(t),l=ref.deref(l);
	//console.log("l=",l,"\n");console.log("t=",t,"\n");
	var res2;
	switch(t) {
		case 0:
	 		res2=rffi.rffi_as_double_ary(res);
	 		break
		case 1:
			res2=rffi.rffi_as_int_ary(res);
			break
	 	case 2:
	 		res2=rffi.rffi_as_int_ary(res);
	 		break
	 	case 3:
	 		res2=rffi.rffi_as_string_ary(res);
	 		break
	}
	res2.length=l;
	return(res2);
}



var isInt=function(x) {
        return (typeof x === 'number') && (x % 1 === 0);
}

var isIntAry=function(arr) {
        return arr.length === arr.filter(isInt).length ;
}

// var isBoolAry=function(arr) {
// 	return arr.map(function(x) {return typeof(x)=='boolean';}).every(function(x) {return x===true;});
// }

var isBoolAry=function(arr) {
	return arr.length === arr.filter(function(x) {return (typeof x === 'boolean');}).length ;
}

var isDoubleAry=function(arr) {
        return arr.length === arr.filter(function(x) {return (typeof x === 'number');}).length ;
}

var isStringAry=function(arr) {
        return arr.length === arr.filter(function(x) {return (typeof x === 'string');}).length ;
}



var set_ary=function(expr,arr) {
	var type = -1,pArr;

	if(isIntAry(arr)) {
		type=1;
		pArr = (new intAry(arr)).buffer;
	} else if(isBoolAry(arr)) {
		type=2;
		pArr = (new intAry(arr)).buffer;
	} else if(isDoubleAry(arr)) {
		type=0;
		pArr = (new doubleAry(arr)).buffer;
	} else if(isStringAry(arr)) {
		type=3;
		pArr = (new stringAry(arr)).buffer;
	}
	if(type>=0) {
		var len = arr.length;
		rffi.rffi_set_ary(".rubyExport",pArr,type,len);
		exec(expr+"<-.rubyExport");
	}
}

if(true) {
	init()
	eval("a=rnorm(10)")
	console.log(get_ary("a"))
	console.log(get_ary("as.integer(1:3)"))
	console.log(get_ary("c('titi','tutu2')"))
	set_ary("a",[1,3,2])
	eval("a")
	set_ary("a",[1.1,3.2,2.3])
	eval("a")
	set_ary("a",[true,false,true])
	eval("a")
	set_ary("a",["tutu","toto2"])
	eval("a")
} else {

	exports.init=init;
	exports.eval=eval;
	exports.exec=exec;
	exports.get_ary=get_ary;
	exports.set_ary=set_ary;

}