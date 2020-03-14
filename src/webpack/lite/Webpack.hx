package webpack.lite;

#if macro
import haxe.macro.Expr;
import haxe.macro.ExprTools;
import haxe.macro.Compiler;
import haxe.macro.Context;
import haxe.macro.Type;
import sys.io.File;
import sys.FileSystem;

using haxe.io.Path;
using StringTools;
#end

class Webpack {
	public static macro function require(file:String):ExprOf<Dynamic> {
		if (!Context.defined('js')) return macro null;

		// Extract inline loaders
		var loaders = '';
		var bang = file.lastIndexOf('!');
		if (bang > 0) {
			loaders = file.substr(0, bang + 1);
			file = file.substr(bang + 1);
		}

		// Adjust relative path
		if (file.startsWith('.')) {
			var posInfos = Context.getPosInfos(Context.currentPos());
			file = rebaseRelativePath(posInfos.file.directory(), file);
		}

		// Add to dependencies
		packages.add(loaders + file);

		return macro webpack.lite.WebpackRuntime.require($v{loaders + file});
	}

	public static macro function load(classRef:Expr):Expr {
		return macro js.lib.Promise.resolve($classRef);
	}

	#if macro
	@:persistent static var packages = new Set();

	static function enableIfDebug():Void {
		if (Context.defined('debug')) {
			Compiler.define(WebpackDefines.Enabled);
		}
	}

	static function register():Void {
		if (Context.defined(WebpackDefines.Enabled)) {
			Context.onGenerate(onGenerate);
			Context.onAfterGenerate(onAfterGenerate);
		}
	}

	static function onGenerate(types:Array<Type>):Void {
		var skipElectron = Context.defined(WebpackDefines.ElectronClient) || Context.defined(WebpackDefines.SkipElectron);

		for (t in types) {
			switch (t) {
				case TInst(_.get() => t, params) if (t.isExtern && t.meta.has(':jsRequire')):
					var pack = ExprTools.getValue(t.meta.extract(':jsRequire')[0].params[0]);

					if (skipElectron && pack == 'electron')
						continue;

					packages.add(pack);

				case _:
			}
		}
	}

	static function onAfterGenerate():Void {
		var out = Compiler.getOutput();
		var outdir = out.directory();
		if (!FileSystem.exists(outdir)) FileSystem.createDirectory(outdir);
		var deps = Path.join([outdir, "dependencies.js"]);

		// TODO: avoid unneeded require() calls (unused externs) => haxe plugin?
		// TODO: generate positions
		// Note: exception is ignored because a webpack warning will be issued anyway
		var packProxies = packages.map(p -> 'try { packages["$p"] = require("$p"); } catch {}').join('\n');

		if (Context.defined(WebpackDefines.ElectronClient)) {
			packProxies += '\ntry { packages["electron"] = window.require("electron"); } catch {}';
		}

		var template = try {
			File.getContent(Context.resolvePath('webpack/lite/dependencies.js'));
		} catch (_:Dynamic) {
			throw 'WebpackLite: Cannot find dependencies.js template';
		};

		var content = template.replace("// Insert packages here", packProxies);
		content = content.replace("$ENTRYPOINT", out.withoutDirectory());

		File.saveContent(deps, content);
	}

	static function rebaseRelativePath(directory:String, file:String) {
		directory = makeRelativeToCwd(directory);
		directory = '${directory}/${file}'.normalize();
		if (directory.isAbsolute() || directory.startsWith('../')) return directory;
		return './$directory';
	}

	static function makeRelativeToCwd(directory:String) {
		directory = directory.removeTrailingSlashes();
		var len = directory.length;

		if (directory.isAbsolute()) {
			var cwd = Sys.getCwd().replace('\\', '/');
			directory = directory.replace('\\', '/');
			if (directory.startsWith(cwd)) return './${directory.substr(cwd.length)}';
			return directory;
		}

		if (directory.startsWith('./') || directory.startsWith('../'))
			return directory;

		return './$directory';
	}
	#end
}
