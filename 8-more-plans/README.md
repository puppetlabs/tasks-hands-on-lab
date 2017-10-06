# Writing more plans

> **Difficulty**: Intermediate

> **Time**: Approximately 15 minutes

In this exercise you will learn how to use the results from running a task
in Puppet Plans.

- [Use minifact for basic node discovery](#use-minifact-for-basic-node-discovery)
- [Run different tasks on different operating systems](#run-different-tasks-on-different-operating-systems)

## Prerequisites

For the following exercises you should already have `bolt` installed and
have a few nodes (either Windows or Linux) available to run commands
against. The following guides will help:

1. [Installing Bolt](../1-installing-bolt)
1. [Acquiring nodes](../2-acquiring-nodes)

It is also useful to have some familiarity with running commands with
`bolt` so you understand passing nodes and credentials. The following
exercises are recommended:

1. [Running Commands](../3-running-commands)
1. [Writing plans](../7-writing-plans)

## Use minifact for basic node discovery

It is common that plans need to make decisions based on the operating
system installed on the remote node. If those nodes have Puppet installed,
you can just run `facter --json` on those nodes with the `run_command`
function you learned about in the last exercise.

If those nodes do not have Puppet installed, you can use the
[`minifact`](https://github.com/puppetlabs/task-modules/blob/master/minifact/tasks/init.sh)
task from the [task-modules](https://github.com/puppetlabs/task-modules)
repo to gather some very basic facts. To do that, check out that repo with
`git clone https://github.com/puppetlabs/task-modules.git`; we will refer
to the location where you checked that repo out as `$task_modules`. You can
now run `minifact` directly using

```bash
bolt --modules $task_modules --nodes <nodes> task run minifact
```

When we need to access the result of running `minifact` inside a plan, we
first assign that result to a variable, and can then access the output from
each node. The result of running a task acts like a hash, where the node
name is the key, and the associated value is the output from the task:

```puppet
   $minifacts = run_task('minifact', $nodes)
   $minifacts.each |$nd, $out| {
     # $nd is the name of the node, and $out contains the output
     # that that node produced
   }
```

The [**run_task documentation**](MISSING LINK) has more details on the
result returned by `run_task`, `run_command`, and `run_script`.

As a simple example of using task results in a plan, we will just print the
output from `minifact` more concisely using a plan. The
[`minifact::info`](https://github.com/puppetlabs/task-modules/blob/master/minifact/plans/info.pp)
plan simply runs `minifact` and then loops over the result:

```puppet
plan minifact::info(String $nodes) {
  $all = $nodes.split(",")
  $minifacts = run_task('minifact', $all)
  $minifacts.each |$nd, $out| {
    util::print("${nd}: ${out[os][name]} ${out[os][release][full]} (${out[os][family]})")
  }
  undef
}
```

Since `minifact` returns a JSON object, Puppet automatically parses that
and makes it available as the Hash that we access with `$out`. If the task
does not return JSON, the entire output can be found in `$out[output]`.

The `minifact::info` plan can be run with
```bash
    bolt --modules $task_modules plan run minifact::info nodes=node1,node2,...
```

## Run different tasks on different operating systems

In heterogeneous environments, it is often necessary to run different tasks
to achieve the same result. As an example, we will write a plan that
collects the versions of installed packages across Debian and Red Hat
machines, but uses different tasks to do so, one using `dpkg` and one using
`rpm`.

To follow along with the example, you will need to copy the `example8`
module to your `$task_modules` directory:

```bash
    cp -pr 8-more-plans/modules/example8 $task_modules
```

The `tasks` directory in `example8` contains two tasks: `dpkg.py`, a Python
script that runs `dpkg` to get information about a package, and `rpm.sh`, a
shell script that does the same using `rpm`. The important thing about them
is that they expect the same input (a package name in `$PT_package`) and
produce a JSON object with the exact same format as output.

The [`example8::packages`](modules/example8/plans/packages.pp) plan first
runs `minifact` on all nodes and uses the `os.family` fact to select nodes
from Debian-like and from RedHat-like nodes. It then runs the
`example8::dpkg` task and the `example8::rpm` task on them and prints
information returned by these. The function `example8::print_node_result`
is a small helper function that just prints the package result from one
node.

```puppet
    plan example8::packages(String $nodes, String $package = "openssl") {
      $all = $nodes.split(",")
      $minifacts = run_task('minifact', $all)

      $debian = $all.filter |$nd| { $minifacts[$nd][os][family] == "Debian" }
      $redhat = $all.filter |$nd| { $minifacts[$nd][os][family] == "RedHat" }

      $rpms = run_task('example8::rpm', $redhat, package => $package)
      $debs = run_task('example8::dpkg', $debian, package => $package)

      $rpms.each |$nd, $out| { example8::print_node_result($nd, $out, "rpm") }
      $debs.each |$nd, $out| { example8::print_node_result($nd, $out, "deb") }

      undef
    }
```

You can run this plan with
```
    bolt --modules $task_modules plan run example8::packages nodes=<nodes> package=openssl
```
