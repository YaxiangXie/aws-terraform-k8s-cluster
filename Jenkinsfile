pipeline{
    agent any
    stages{
        stage('拉取 Git 倉庫代碼'){
            git(
                url: 'http://140.133.76.188/clsrebuild/terraform_k8s.git',
                branch: 'main',
                credentialsId: '1',
            )
        }
        
        stage('通過 Dockerfile 建立自訂義的 image'){
            steps{
                echo "build custom image by Dockerfile"
            }
        }
        
        stage('將自訂義的 image 上傳至 Harbor'){
            steps{
                echo "push custom image to Harbor"
            }
        }
        
        stage('通過 Publish Over SSH 通知目標服務器'){
            steps{
                echo "notify target server through Publish Over SSH"
            }
        }
    }
}