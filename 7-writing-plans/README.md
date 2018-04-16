# Writing Plans

> **Difficulty**: Intermediate

> **Time**: Approximately 10 minutes

In this exercise you will discover Puppet Plans and how to run them with Bolt. 

- [Write a plan using run_command](#write-a-plan-using-run_command)
- [Write a plan using run_task](#write-a-plan-using-run_task)

# Prerequisites
Complete the following before you start this lesson:

1. [Installing Bolt](../1-installing-bolt)
1. [Setting up test nodes](../2-acquiring-nodes)
1. [Running Commands](../3-running-commands)

# About Plans 

Use plans when you want to run several commands together across multiple nodes. For instance to remove a node from a load balancer before you deploy the new version of the application, or to clear a cache after you re-index a search engine.

You can link a set of commands, scripts, and tasks together, and add parameters to them so they are easy to reuse. While you write plans in the Puppet language, you don't need to install Puppet to use them.


# Write a plan using run_command

Create a simple plan that runs a command on a list of nodes.

1. Save the following as `modules/exercise7/plans/command.pp`:

    ```puppet
    plan exercise7::command (TargetSpec $nodes) {
      run_command("uptime", $nodes)
    }
    ```

2. Run the plan:

    ```
    $ bolt plan run exercise7::command nodes=all --modulepath ./modules
    2018-02-16T15:35:47.843668 INFO   Bolt::Executor: Starting command run 'uptime' on ["node1"]
    2018-02-16T15:35:48.154690 INFO   Bolt::Executor: Ran command 'uptime' on 1 node with 0 failures
    [
      {
        "node": "node1",
        "status": "success",
        "result": {
          "stdout": " 23:35:48 up 2 min,  0 users,  load average: 0.10, 0.09, 0.04\n",
          "stderr": "",
          "exit_code": 0
        }
      }
    ]
    ```

    **Note:**

    * `nodes` is passed as an argument like any other, rather than a flag. This makes plans flexible when it comes to taking lists of different types of nodes or generating the list of nodes in code within the plan.

    * Use the `TargetSpec` type to denote nodes; it allows passing a single string describing a target URI or a comma-separated list of strings as supported by the `--nodes` argument to other commands. It also accepts an array of Targets, as resolved by calling the [`get_targets` method](https://puppet.com/docs/bolt/0.x/writing_plans.html#calling-basic-plan-functions). You can iterate over Targets without needing to do your own string splitting, or as resolved from a group in an [inventory file](https://puppet.com/docs/bolt/0.x/inventory_file.html).


# Write a plan using run_task
Create a task and then create a plan that uses the task. .

1. Save the following task as `modules/exercise7/tasks/write.sh`. The task accepts a filename and some content and saves a file to 1`/tmp`.
    
    ```bash
    #!/bin/sh
    
    if [ -z "$PT_message" ]; then
      echo "Need to pass a message"
      exit 1
    fi
    
    if [ -z "$PT_filename" ]; then
      echo "Need to pass a filename"
      exit 1
    fi
    
    echo $PT_message > "/tmp/${PT_filename}"
    ```

2. Run the task directly with the following command:

    ```
    bolt task run exercise7::write filename=hello message=world --nodes=all --modulepath ./modules --debug
    ```
    
    **Note:** In this case the task doesn't output anything to stdout. It can be useful to trace the running of the task, and for that the `--debug` flag is useful. Here is the output when run with debug:
    
    ```
    2018-02-16T15:36:31.643418 DEBUG  Bolt::Inventory: Did not find node1 in inventory
    2018-02-16T15:36:32.713360 DEBUG  Bolt::Executor: Started with 100 max thread(s)
    2018-02-16T15:36:32.932771 DEBUG  Bolt::Inventory: Did not find node1 in inventory
    2018-02-16T15:36:32.932869 INFO   Bolt::Executor: Starting task exercise7::write on ["node1"]
    2018-02-16T15:36:32.932892 DEBUG  Bolt::Executor: Arguments: {"filename"=>"hello", "message"=>"world"} Input method: both
    2018-02-16T15:36:33.178433 DEBUG  Bolt::Transport::SSH: Authentication method 'gssapi-with-mic' is not available
    2018-02-16T15:36:33.179532 DEBUG  Bolt::Transport::SSH: Running task run 'Task({'name' => 'exercise7::write', 'executable' => '/Users/michaelsmith/puppetlabs/tasks-hands-on-lab/7-writing-plans/modules/exercise7/tasks/write.sh'})' on node1
    Started on node1...
    2018-02-16T15:36:33.216451 DEBUG  node1: Opened session
    2018-02-16T15:36:33.216604 DEBUG  node1: Executing: mktemp -d
    2018-02-16T15:36:33.395440 DEBUG  node1: stdout: /tmp/tmp.I7ZTz4OmfY
    
    2018-02-16T15:36:33.395746 DEBUG  node1: Command returned successfully
    2018-02-16T15:36:33.411634 DEBUG  node1: Executing: chmod u+x '/tmp/tmp.I7ZTz4OmfY/write.sh'
    2018-02-16T15:36:33.423831 DEBUG  node1: Command returned successfully
    2018-02-16T15:36:33.424137 DEBUG  node1: Executing: PT_filename='hello' PT_message='world' '/tmp/tmp.I7ZTz4OmfY/write.sh'
    2018-02-16T15:36:33.436180 DEBUG  node1: Command returned successfully
    2018-02-16T15:36:33.436226 DEBUG  node1: Executing: rm -rf '/tmp/tmp.I7ZTz4OmfY'
    2018-02-16T15:36:33.447658 DEBUG  node1: Command returned successfully
    2018-02-16T15:36:33.447850 DEBUG  node1: Closed session
    2018-02-16T15:36:33.447918 DEBUG  Bolt::Transport::SSH: Result on node1: {"_output":""}
    Finished on node1:
    
      {
      }
    2018-02-16T15:36:33.448381 INFO   Bolt::Executor: Ran task 'exercise7::write' on 1 node with 0 failures
    Ran on 1 node in 0.74 seconds
    ```
3. Write a plan that uses the task you created. Save the following as `modules/exercise7/plans/writeread.pp`:

    ```puppet
    plan exercise7::writeread (
      TargetSpec $nodes,
      String     $filename,
      String     $message = 'Hello',
    ) {
      run_task(
        'exercise7::write',
        $nodes,
        filename => $filename,
        message  => $message,
      )
      run_command("cat /tmp/${filename}", $nodes)
    }
    ```

    **Note:**
    
    * The plan takes three arguments, one of which (`message`) has a default value. We'll see shortly how Bolt uses that to validate user input.
    * Use the Puppet `split` function to support passing a comma-separated list of nodes. Plans are just Puppet, so you can use any of the available [functions](https://docs.puppet.com/puppet/latest/function.html) or [native data types](https://docs.puppet.com/puppet/latest/lang_data_type.html).
    * First you run the `exercise7::write` task from above, setting the arguments for the task to the values passed to the plan. This writes out a file in the `/tmp` directory.
    * Then you run a command directly from the plan, in this case to output the content written to the file in the above task.

4. Run the plan using the following command:
    
    ```
    bolt plan run exercise7::writeread filename=hello message=world nodes=<nodes> --modulepath ./modules
    ```

    Note:
    
    * `message` is optional. If it's not passed it uses the default value from the plan.
    * When running multiple steps in a plan only the last step will generate output.


# Next steps

Now that you know how to create and run basic plans with Bolt you can move on to:

[Writing advanced Tasks](../8-writing-advanced-tasks)
