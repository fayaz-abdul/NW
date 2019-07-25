def dockerCredentials = 'BxMgmtLon_docker_credentials'
def gitlabCredentials = 'BxMgmtLon_gitlab_jenkins_credentials'

def pipelineName = "_docker_images"

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

pipelineJob("${pipelineName}") {
  description "Base image"
  parameters {
    stringParam ('IMAGE_VERSION', 'latest', 'Docker Container Code Version')
  }
  definition {
    cpsScm {
      scm {
        git {
          remote {
            url "ssh://git@gitlab.bx.homeoffice.gov.uk/devops/docker-images.git"
            credentials(gitlabCredentials)
          }
        }
      }
      scriptPath('Jenkinsfile')
    }
    triggers {
      cron('1 6 * * 1,2,3,4,5')
    }
    logRotator(2,10,-1,-1)
    concurrentBuild(false)
  }
}
