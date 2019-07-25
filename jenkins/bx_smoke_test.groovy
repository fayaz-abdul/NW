// Hierarchy:
// pipeline / environment / stage

def pipelineDefaults = [
        // options relevant to pipelineJobParameters
        image               : "latest",
        official            : true,
        smoke_test_suite    : "all-gw-off",
        disabled            : false
]

def pipelines = [
        [name: "BxMgmtLon"]
]

for (pipeline in pipelines) {
    for (pipelineDefault in pipelineDefaults) {
        if (pipeline[pipelineDefault.key] == null) {
            pipeline[pipelineDefault.key] = pipelineDefault.value
        }
    }
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
    pipelineName = "${pipeline.name}_Smoke_Test"
    environmentName = "${pipeline.name}"
    pipelineHour = "${pipeline.hour}"
    jobName = "${pipelineName}"
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

//  https://jenkinsci.github.io/job-dsl-plugin/#path/pipelineJob-parameters
    pipelineJobParametersBuild = {
      stringParam('ENVIRONMENT', "${environmentName}", 'Deployment Environment')
      stringParam('IMAGE_VERSION', "${pipeline.image}", 'Docker Container Code Version')
      stringParam('AWS_CREDENTIALS', "${environmentName}_aws_credentials", 'AWS Jenkins Credentials ID')
      stringParam('AWS_DEFAULT_REGION', 'eu-west-2', 'AWS Region')
      stringParam('DOCKER_CREDENTIALS', "${environmentName}_docker_credentials", 'HO Docker Credentials')
      stringParam('GITLAB_ENVIRONMENT', "${environmentName}_gitlab_jenkins_credentials", 'GitLab Data Platform Environment Credentials ID')
      stringParam('SSH_CREDENTIALS', "${environmentName}_ssh_credentials", 'Jenkins SSH Key')
      stringParam('ANSIBLE_CREDENTIALS', "${environmentName}_ansible_credentials", 'Ansible Vault Password')
      stringParam('SMOKE_TEST_SUITE', pipeline.smoke_test_suite, 'Smoke test suite to be run')
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
      description "Smoke Test for ${environmentName}"
      disabled(pipeline.disabled)
      parameters pipelineJobParametersBuild
      definition {
          cpsScm {
            scm scmParameters
            scriptPath(getJenkinsfileName(pipeline, 'smoke_test'))
          }
          logRotator(2, -1, -1, -1)
          concurrentBuild(false)
      }
      triggers {
        cron('H/15 * * * *')
      }
   }
}
