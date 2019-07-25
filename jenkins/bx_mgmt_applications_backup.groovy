// Hierarchy:
// pipeline / environment / stage

def pipelineDefaults = [
        // options relevant to pipelineJobParameters
        image               : "latest",
        official            : true,
        disabled            : false
]

def pipelines = [
        [name: "BxMgmtLon", disabled: false],
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
    pipelineName = "${pipeline.name}_Mgmt_Application_Backup"
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
      choiceParam('APP', ['all', 'jenkins', 'jenkins-dev', 'artifactory', 'gitlab'], 'List of Applications to backup')
      stringParam('ENVIRONMENT', "${environmentName}", 'Deployment Environment')
      stringParam('IMAGE_VERSION', "latest", 'Image Version')
      stringParam('AWS_CREDENTIALS', "${environmentName}_aws_credentials", 'AWS Jenkins Credentials ID')
      stringParam('AWS_DEFAULT_REGION', 'eu-west-2', 'AWS Region')
      stringParam('DOCKER_CREDENTIALS', "${environmentName}_docker_credentials", 'HO Docker Credentials')
      stringParam('GITLAB_ENVIRONMENT', "${environmentName}_gitlab_jenkins_credentials", 'GitLab Data Platform Environment Credentials ID')
      stringParam('SSH_CREDENTIALS', "${environmentName}_ssh_credentials", 'Jenkins SSH Key')
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
      description "Management Application Backup"
      disabled(pipeline.disabled)
      parameters pipelineJobParametersBuild
      definition {
          cpsScm {
            scm scmParameters
            scriptPath(getJenkinsfileName(pipeline, 'backup'))
          }
          logRotator(2, 50, -1, -1)
          concurrentBuild(false)
      }
      triggers {
        cron('H 2 * * *')
      }
   }
}
