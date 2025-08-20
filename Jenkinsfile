pipeline{
    agent any

    environment {
        project_name = "clsn-demo"
        TG_BOT_TOKEN = credentials('tg-bot-token')
        TG_CHAT_ID = credentials('tg-chat-id')
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
                            docker rmi 203.64.95.35:8853/library/${project_name}:latest
                            docker rmi ${project_name}:latest
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
    post {
    success{
        sh '''
            curl -s -X POST https://api.telegram.org/bot${TG_BOT_TOKEN}/sendMessage \
            -d chat_id=${TG_CHAT_ID} \
            -d text="Pipeline succeeded: ${project_name}"
        '''
    }

    failure{
        sh '''
            curl -s -X POST https://api.telegram.org/bot${TG_BOT_TOKEN}/sendMessage \
            -d chat_id=${TG_CHAT_ID} \
            -d text="Pipeline failed: ${project_name}"
        '''
    }

}
}