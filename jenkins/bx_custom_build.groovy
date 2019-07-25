def gitlabEnvironment = 'BxNProdJenkins_gitlab_jenkins_credentials'

// Hierarchy:
// pipeline / environment / stage

// depth: the total number of environments in a pipeline
// environmentWhitelist: permissible environments (constrained by depth, empty is unenforced)
def pipelineDefaults = [
        depth               : 1,
        environmentWhitelist: [],
        // options relevant to pipelineJobParameters
        image               : "latest",
        official            : true,
        postgres            : true,
        terraform           : true,
        disabled            : false
]

// depth denotes how many of the following to create
// if environmentWhitelist is populated only those listed may be created
def environments = [
        [name: "Dev"],
        [name: "CI"],
        [name: "QA"],
        [name: "Stg"],
        [name: "Pre"],
        [name: "Prod"]
]

def pipelines = [
        [name: "BxNProdInfAMI", hour: 2],
]

def pipelineEnvironmentOrderingTokens = [
        'a', 'b', 'c', 'd', 'e', 'f', 'g', 'h'
]

for (pipeline in pipelines) {
    for (pipelineDefault in pipelineDefaults) {
        if (pipeline[pipelineDefault.key] == null) {
            pipeline[pipelineDefault.key] = pipelineDefault.value
        }
    }
}


def isInWhitelist(environmentName, pipeline) {
    if (pipeline.environmentWhitelist && !(environmentName in pipeline.environmentWhitelist)) {
        return false
    }
    return true
}

def getJenkinsfileName(pipeline, stage = '') {
    if (pipeline.jenkinsfile) {
        fileName = pipeline.jenkinsfile
    } else {
        fileName = 'Jenkinsfile'
    }
    return fileName + (stage ? ".${stage}" : '')
}

def getBranch(pipeline) {
    if (pipeline.branch) {
        return pipeline.branch
    }
    return '*/master'
}

pipelines.each { pipeline ->

    deployedEnvironmentCount = 0

    environments.eachWithIndex { environment, pipelineStageCount ->

        if (pipeline.depth && deployedEnvironmentCount >= pipeline.depth) {
            return false
        }

        if (!isInWhitelist(environment.name, pipeline)) {
            return false
        }

        deployedEnvironmentCount++

        pipelineName = "${pipeline.name}"
        environmentName = "${pipelineName}${environment.name}"
        pipelineHour = "${pipeline.hour}"
	pipelineStage = pipelineEnvironmentOrderingTokens[pipelineStageCount]
        jobName = "${pipelineName}_${pipelineStage}_${environment.name}"
        jobNameDestroy = "${jobName}_DESTROY"
        jobNameTest = "${jobName}_test"

        listView("${pipelineName}") {
            description("View for ${pipelineName}")
            jobs {
                regex(/^${pipelineName}.*/)
            }
            columns {
                status()
                weather()
                name()
                lastSuccess()
                lastFailure()
                lastDuration()
                buildButton()
            }
        }

//        https://jenkinsci.github.io/job-dsl-plugin/#path/pipelineJob-parameters
        pipelineJobParametersDefault = {
            stringParam('ENVIRONMENT', "${environmentName}", 'Deployment Environment')
            stringParam('IMAGE_VERSION', "${pipeline.image}", 'Docker Container Code Version')
            stringParam('AWS_CREDENTIALS', "${environmentName}_aws_credentials", 'AWS Jenkins Credentials ID')
            stringParam('AWS_DEFAULT_REGION', 'eu-west-2', 'AWS Region')
            stringParam('DOCKER_CREDENTIALS', "${environmentName}_docker_credentials", 'HO Docker Credentials')
            stringParam('GITLAB_ENVIRONMENT', "${environmentName}_gitlab_jenkins_credentials", 'GitLab Data Platform Environment Credentials ID')
            stringParam('SSH_CREDENTIALS', "${environmentName}_ssh_credentials", 'Data Layer Jenkins SSH Key')
            stringParam('ANSIBLE_CREDENTIALS', "${environmentName}_ansible_credentials", 'Ansible Vault Password')
            booleanParam('POSTGRES', pipeline.postgres, 'Deploying Postgres')
            booleanParam('TERRAFORM', pipeline.terraform, 'Deploying in AWS via Terraform')
        }


        pipelineJobParametersBuild = {
//           START_AT_STAGE generated from (adjust path for your machine):
            // AJM: this expression no longer works :/
//           echo "['', $(grep '_stage(' /usr/src/ho/data_platform_environments/Jenkinsfile | sed -E 's#.*\(([^\)]*).*#\1#g' | grep -E -v "^'(Cleanup|Checkout)" | tr '\n' ',' | sed 's/.$//'; echo)]"
            choiceParam('START_AT_STAGE', ['', 'Test VPC Peering', 'Build AWS Environment', 'Test Terraform', 'Provision Users',
                                           'Test Provision Users', 'Base Build of Servers', 'Test Base Build'],
                    'Start at stage')
        }

        pipelineJobParametersTest = {
            stringParam('SERVERSPEC_ROLES_ALL', "base,", 'Serverspec Roles to run on all servers (comma delimited)')
            stringParam('SERVERSPEC_ROLES_MASTER', "master,", 'Serverspec Roles to run on master(s)  (comma delimited)')
        }

        pipelineJobParametersDataIngest = {
            stringParam('BDRM_SERVER', "127.0.0.1", 'BDRM server address')
        }

        scmParameters = {
            git {
                remote {
                    url "ssh://git@gitlab.bx.homeoffice.gov.uk/devops/data_platform_environments.git"
                    credentials("${environmentName}_gitlab_jenkins_credentials")
                }
                branch(getBranch(pipeline))
            }
        }

        pipelineJob(jobName) {
            description "Create ${environmentName} Data Platform AMI"
            disabled(pipeline.disabled)
            parameters pipelineJobParametersDefault << pipelineJobParametersBuild
            definition {
                cpsScm {
                    scm scmParameters
                    scriptPath(getJenkinsfileName(pipeline, 'ami'))
                }
                logRotator(2, 50, -1, -1)
                concurrentBuild(false)
            }
        }

        pipelineJob(jobNameTest) {
            description "Test ${environmentName} Data Platform AMI"
            disabled(pipeline.disabled)
            parameters pipelineJobParametersDefault << pipelineJobParametersTest
            definition {
                cpsScm {
                    scm scmParameters
                    scriptPath(getJenkinsfileName(pipeline, 'test'))
                }
                logRotator(2, 50, -1, -1)
                concurrentBuild(false)
            }
        }

        pipelineJob(jobNameDestroy) {
            description "DESTROY ${environmentName} Data Platform AMI"
            disabled(pipeline.disabled)
            parameters pipelineJobParametersDefault
            definition {
                cpsScm {
                    scm scmParameters
                    scriptPath(getJenkinsfileName(pipeline, 'destroy'))
                }
                logRotator(2, 10, -1, -1)
                concurrentBuild(false)
            }
        }

    }
}
