========================
Github Deploy :dog: 
========================

.. image:: https://svgshare.com/i/Zhy.svg
    :target: https://svgshare.com/i/Zhy.sv

.. image:: https://img.shields.io/badge/Maintained%3F-yes-green.svg
    :target: https://github.com/n4b3ts3/github_deploy/graphs/commit-activity

.. image:: https://img.shields.io/github/license/n4b3ts3/github_deploy.svg
    :target: https://github.com/n4b3ts3/github_deploy/blob/master/LICENSE

.. image:: https://img.shields.io/github/release/n4b3ts3/github_deploy.svg
    :target: https://github.com/n4b3ts3/github_deploy/releases/

.. image:: https://img.shields.io/github/issues/n4b3ts3/github_deploy.svg
    :target: https://img.shields.io/github/release/n4b3ts3/github_deploy/issues/

.. image:: https://badgen.net/badge/Open%20Source%20%3F/Yes%21/blue?icon=github
    :target: https://github.com/n4b3ts3/github_deploy/

------------
How to use
------------
First, create a file inside the ~/.github_deploy/ folder, for example, example.env
Is very important the .env part if the file doesnt end with that it wont be recognized by the script.
For security reasons you may need to use GPG in the .env file, for that please set the GPG_PROJECT environment to any value 
So lets say we have an original .env file like follows.

.. code-block:: bash

    export GD_USERNAME=<your-username>
    export PAT=<your-encrypted-pat>
    export REPOSITORY=<your-repository>
    export BRANCH=<your-target-branch>
    export TAG=<vX.X.X>
    export DESCRIPTION=<your-release-description>
    export PRERELEASE=<true|false>
    export GEN_PREREL_NOTES=<true|false>
    export DRAFT=<true|false>

then we have to use the next over our previously created .env file:

.. code-block:: bash

    gpg -r <your-key-id> -e <your-file>.env 


the previous will create a file called example.env.gpg, `PLEASE NOTE THAT IF THE FILE DOESNT ENDS WITH .env.gpg or .env THE SCRIPT IS NOT GOING TO RECOGNIZE IT` 
Now, please delete the .env file for security reasons (SO NO ONE WITHOUT ACCESS TO YOUR GPG Key wont be able to access the release configurations)
Finally, lets do as follows in your Jenkinsfile

.. code-block:: groovy

    pipeline{
        agent any
        stages{
            stage("Build"){
                steps{
                    sh "echo Do your Build steps as you pleased"
                }
            }
            
            stage("Test"){
                steps{
                    sh "echo Do your Test steps as you pleased"
                }
            }

            stage("Release"){
                steps{
                    sh "export PROJECT_REGEX="<your-project-id>" && github_deploy.sh /path/to/my/build1 /path/to/my/build2 /path/to/my/buildn <<< <your-key-id>"
                }
            }

            stage("Deploy"){
                steps{
                    sh "echo Do your Deploy steps as you pleased"
                }
            }
        }
    }

for specifying a custom project to deploy you must set PROJECT_REGEX environment or variable when calling this script. This allow us to use the value
of that var to create a custom regex matching the configuration file...
You may also want to create a dynamic .env file in your project, for the purpose of updating your release descriptions or updating your tag name etc...
for that purpose create a file using the syntax of KEY: VALUE like follow:

.. code-block::

    TAG: v1.0.3
    DESCRIPTION: MY BEAUTIFUL DESCRIPTION WITHOUT NEW LINES PLEASE

The previous .env file can have any key described at the top of this README (at location ~/.github_deploy) 

---------------
How to install
---------------
If you want to install this to your system please do as follows

.. code-block:: bash

    wget https://github.com/n4b3ts3/github_deploy/releases/download/v1.0.3/github_deploy.zip
    unzip github_deploy
    mv `pwd`/github_depleloy.sh /usr/local/bin/git-deploy 



---------------
Maintainers
---------------
.. image:: https://img.shields.io/badge/maintainer-n4b3ts3-blue
    :target: mailto://n4b3ts3@gmail.com

