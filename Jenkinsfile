pipeline{
    agent any

    environment {
        project_name = "clsn-demo"
        harborUser = 'ants'
        harborPassword = 'your_harbor_password'
    }

    stages{
        stage('拉取 Git 倉庫代碼'){
            steps{
                git(
                url: 'http://140.133.76.188/clsrebuild/terraform_k8s.git',
                branch: 'main',
                credentialsId: '1',
             )
            }
        }
        
        stage('通過 Dockerfile 建立自訂義的 image'){
            steps{
                sh '''
                docker build -t ${project_name}:latest .
                '''
            }
        }
        
        stage('將自訂義的 image 上傳至 Harbor'){
            steps{
                timeout(time: 3, unit: 'MINUTES'){
                    withCredentials([usernamePassword(credentialsId: 'harbor-credentials', passwordVariable: 'HARBOR_PASSWORD', usernameVariable: 'HARBOR_USERNAME')]) {
                        sh '''
                            docker tag ${project_name}:latest 203.64.95.35:8853/library/${project_name}:latest
                            echo ${HARBOR_PASSWORD} | docker login 203.64.95.35:8853 -u ${HARBOR_USERNAME} --password-stdin
                            docker push 203.64.95.35:8853/library/${project_name}:latest
                        '''
                    }
                }
            }
        }
        
        stage('通過 Publish Over SSH 通知目標服務器'){
            steps{
                echo "notify target server through Publish Over SSH"
            }
        }
    }
}