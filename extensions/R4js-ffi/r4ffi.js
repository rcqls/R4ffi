var ref=require("ref");
var RefArray = require('ref-array');
var ffi=require("ffi");

var intPtr=ref.refType("int");
var voidPtr=ref.refType("void");
var doubleAry=RefArray("double");
//var VoidArray=RefArray("void");
var intAry=RefArray("int");

var rffi=ffi.Library(process.env["R4FFI_LIB"] || "/Users/remy/devel/R4ffi/build/lib/libRffi.dylib",{
	"rffi_init":["int",["string"]],
	"rffi_eval":["int",["string","int"]],
	"rffi_get_ary":[voidPtr,["string",intPtr,intPtr]],
	"rffi_as_double_ary":[doubleAry,[voidPtr]],
	"rffi_as_int_ary":[intAry,[voidPtr]],
	"rffi_set_ary":["void",["string","pointer","int","int"]],
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
	// 	case 2:
	// 		//res.read_array_of_int(len).map{|e| e==0 ? false : true}
	}
	res2.length=l;
	return(res2);
}

var set_ary=function(expr,arr) {
		var type = 1;
		var pArr = new intAry(arr);
		var len = arr.length;
		var res=rffi.rffi_set_ary(".rubyExport",pArr,type,len);
		exec(expr+"<-.rubyExport");
}

exports.init=init;
exports.eval=eval;
exports.exec=exec;
exports.get_ary=get_ary;
exports.set_ary=set_ary;