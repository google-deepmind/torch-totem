# Totem - Torch test module

Totem is a small test package in the style of torch.Tester. The interface is
essentially the same as torch.Tester but differs/extends it in the following
ways:

* the test runner has different output (with colours!)
* the test runner can output test results in a simple machine-readable file
* the package includes some standard tests for nn modules

## Basic test description

A test script can be written as follows:

	require 'totem'

	local mytest = {}
	 
	local tester = totem.Tester()
	 
	function mytest.TestA()
		local a = 10
		local b = 10
		tester:asserteq(a, b, 'a == b')
		tester:assertne(a,b,'a ~= b')
	end
	 
	function mytest.TestB()
		local a = 10
		local b = 9
		tester:assertlt(a, b, 'a < b')
		tester:assertgt(a, b, 'a > b')
	end
	 
	return tester:add(mytest):run()

The command `totem-init` can be used to generate an empty test.

## Command-line usage

When running the script from the command-line you get a number of options:

```sh
Run tests

Usage:

  ./simple.lua [options] [test1 [test2...] ]

Options:

  --list print the names of the available tests instead of running them.
  --log-output (optional file-out) redirect compact test results to file.
        This contains one line per test in the following format:
        name #passed-assertions #failed-assertions #exceptions
  --no-colour suppress colour output
  --summary print only pass/fail status rather than full error messages.
  --full-tensors when printing tensors, always print in full even if large.
        Otherwise just print a summary for large tensors.
  --early-abort (optional boolean) abort execution on first error.

If any test names are specified only the named tests are run. Otherwise
all the tests are run.
```

## Nesting tests

It's possible to nest test cases. Individual test files are still assumed to be
runnable as stand-alone scripts, but a test case can include the outputs of
such files. For example

        require 'totem'

        local test = {}
        local tester = totem.Tester()
        tester:add('test_nn.lua')
        tester:add('test_simple.lua')
        tester:add('test_tensor.lua')
        return tester:run()

will first run all the tests in each of the listed test files and then report
the overall test results. Each test is considered to pass only if all of its
subtests pass.
