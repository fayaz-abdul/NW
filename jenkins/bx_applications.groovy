def gitlabEnvironment = 'BxNProdJenkins_git_environment_credential'

def pipelineName = "example-application"

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
  description "Deploy an example application"
  parameters {
    stringParam ('IMAGE_VERSION', 'latest', 'Docker Container Code Version')
    stringParam ('DOCKER_CREDENTIALS', '6bb93ed7-8853-475f-95ae-895460e1c74c', 'HO Docker Credentials') 
  }
  definition {
    cpsScm {
      scm {
        git {
          remote {
            url("ssh://git@gitlab.bx.homeoffice.gov.uk/borders/example-deployment-pipeline.git")
            credentials(gitlabEnvironment)
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
