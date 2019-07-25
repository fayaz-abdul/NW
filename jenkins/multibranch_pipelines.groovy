// Hierarchy:
// pipeline / environment / stage
import java.nio.charset.Charset

String gitlabCredentials = "BxMgmtLon_gitlab_jenkins_credentials"

def jobDefn = 	[
        "Infra BX MultiBranch Projects"	:	// Each Element is a Entry with Key being the project Name and Value being the Git URL
                [
                        "Infra Build Tools Container"	:	"ssh://git@gitlab.bx.homeoffice.gov.uk/devops/infra-build-tools.git"
                ]

]

jobDefn.each { entry ->
    projectsView = "${entry.key}";
    println "View  " + "${projectsView}"
    entry.value.each { job ->
        jobName = job.key;
        jobVCS = job.value;
        println "Job  " + "${jobName}"
        buildMultiBranchJob(jobName, jobVCS, gitlabCredentials)
    }
    listView("${projectsView}") {
        jobs {
            entry.value.each { job ->
                jobName = job.key;
                name("${jobName}")
            }
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
}
// Code used by AFTC in their Prod Jenkins
def buildMultiBranchJob(String jobName, jobVCS, credentials) {
    multibranchPipelineJob(jobName) {
        branchSources {
          // Ensure that all branches of the project repo are polled and built.
            branchSourceNodes << new NodeBuilder().'jenkins.branch.BranchSource' {
                source(class: 'jenkins.plugins.git.GitSCMSource') {
                    id(UUID.nameUUIDFromBytes(jobName.getBytes(Charset.forName("UTF-8"))))
                    remote(jobVCS)
                    credentialsId(credentials)
                    includes('*')
                    ignoreOnPushNotifications(false)
                    extensions {
                        localBranch(class: "hudson.plugins.git.extensions.impl.LocalBranch") {
                            localBranch('**')
                        }
                    }
                }
            }
        }
        triggers {
            periodic(1)
        }
        orphanedItemStrategy {
            discardOldItems {
                daysToKeep(0)
                numToKeep(0)
            }
        }
    }
}
