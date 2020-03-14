package webpack.lite;

@:native('window')
extern class WebpackRuntime {
	static function require<T>(mod:String):T;
	static function nativeRequire<T>(mod:String):T;
}
