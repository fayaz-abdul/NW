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
    pipelineName = "${pipeline.name}_docker_images_cleanup"
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
      stringParam('GITLAB_ENVIRONMENT', "${environmentName}_gitlab_jenkins_credentials", 'GitLab Data Platform Environment Credentials ID')
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
      description "Cleanup docker images "
      disabled(pipeline.disabled)
      parameters pipelineJobParametersBuild
      definition {
          cpsScm {
            scm scmParameters
            scriptPath(getJenkinsfileName(pipeline, 'cleanup'))
          }
          logRotator(2, 50, -1, -1)
          concurrentBuild(false)
      }
      triggers {
        cron('H 1 * * *')
      }
   }
}
