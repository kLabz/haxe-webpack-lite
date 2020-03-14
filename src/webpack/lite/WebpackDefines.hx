package webpack.lite;

// TODO: add documentation
enum abstract WebpackDefines(String) to String {
	var Enabled = 'webpack.lite.enabled';
	var ElectronClient = 'webpack.lite.electronClient';
	var SkipElectron = 'webpack.lite.skipElectron';
}
