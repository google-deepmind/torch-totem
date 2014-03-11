package = 'totem'
version = '0-0'

source = {
	url = 'https://github.com/akfidjeland/torch-totem.git',
	branch = 'master'
}


description = {
	summary = 'Torch test module',
	homepage = 'https://github.com/akfidjeland/torch-totem'
}

dependencies = { 'torch >= 7.0', 'sys', 'penlight', 'nn'}
build = {
	type = 'builtin',
	modules = {
		['totem.init'] = 'src/init.lua',
		['totem.nn'] = 'src/nn.lua',
		['totem.Tester'] = 'src/Tester.lua',
		['totem.examples.test_simple'] = 'examples/test_simple.lua',
		['totem.examples.test_nn'] = 'examples/test_nn.lua',
	},
	install = {
		bin = {
			'scripts/totem-init'
		}
	}
}
