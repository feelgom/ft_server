# ft_server

> **참고한 글들**
`daehyunlee`'s [[ft_server] 선행지식](https://velog.io/@hidaehyunlee/ftserver-선행지식-Docker-Debian-Buster-Nginx-)
`daehyunlee`'s [[ft_server] 총 정리 : 도커 설치부터 워드프레스 구축까지](https://velog.io/@hidaehyunlee/ftserver-총-정리-도커-설치부터-워드프레스-구축까지)
`daehyunlee`'s [[ft_server] 마무리 : Dockerfile 만들기](https://velog.io/@hidaehyunlee/ftserver-마무리-Dockerfile-만들기)
> 

# 1. 도커 설치

[Docker for Mac](https://hub.docker.com/editions/community/docker-ce-desktop-mac/) 에서 Stable version 설치

# 2. 도커로 데비안 버스터 이미지 생성

```
docker pull debian:buster
```

확인하려면 `docker images`

# 3. 도커로 데비안 버스터 환경 실행 및 접속

```
docker run -it --name con_debian -p 80:80 -p 443:443 debian:buster
```

- `-i` 옵션은 interactive(입출력), `-t` 옵션은 tty(터미널) 활성화
    - 즉 일반적으로 터미널 사용하는 것처럼 컨테이너 환경을 만들어주는 옵션
- `--name [컨테이너 이름]` 옵션을 통해 컨테이너 이름을 지정할 수 있다. 안하면 랜덤으로 생성?
- `-p` 호스트포트:컨테이너포트 옵션은 컨테이너의 포트를 개방한 뒤 호스트 포트와 연결한다.
    - 컨테이너 포트와 호스트 포트에 대한 개념이 궁금하다면 [여기](https://blog.naver.com/alice_k106/220278762795) 참고

# 4. 데비안 버스터에 Nginx, cURL 설치

```
apt-get -y install nginx curl
```

- 데비안에서는 패키지 매니저로 [apt-get](https://www.notion.so/apt-get-f709bed866984eda93febb3e77ff2031) 을 사용한다.
    - 설치가 잘 안될때는 `apt-get update`, `apt-get upgrade` 진행하고 다시 설치
- `cURL`은 서버와 통신할 수 있는 커맨드 명령어 툴이다. **url을 가지고 할 수 있는 것들은 다할 수 있다.**예를 들면, http 프로토콜을 이용해 웹 페이지의 소스를 가져온다거나 파일을 다운받을 수 있다. ftp 프로토콜을 이용해서는 파일을 받을 수 있을 뿐 아니라 올릴 수도 있다.
    - 자세한 curl 사용법과 옵션은 [여기](https://shutcoding.tistory.com/23) 참고.

# 5. Nginx 서버 구동 및 확인

- nginx 서버 실행
    
    ```
    service nginx start
    ```
    
- nginx 상태 확인
    
    ```
    service nginx status
    ```
    
    `[ ok ] nginx is running.` 가 뜨면 서버가 잘 돌아가고 있다는 뜻이다.
    
    localhost:80 에 접속해보면 서버와의 성공적인 첫 소통을 확인할 수 있다.
    
    ![스크린샷 2021-10-20 오전 12.20.49.png](https://s3-us-west-2.amazonaws.com/secure.notion-static.com/480339ea-7bc1-4bd2-ab32-ee063035dc86/스크린샷_2021-10-20_오전_12.20.49.png)
    

# 6. self-signed SSL 인증서 생성

- HTTPS(Hypertext Transfer Protocol over Secure Socket Layer)는 `SSL`위에서 돌아가는 HTTP의 평문 전송 대신에 **암호화된 통신을 하는 프로토콜**이다.
- 이런 HTTPS를 통신을 서버에서 구현하기 위해서는 *신뢰할 수 있는 상위 기업*이 발급한 인증서가 필요로 한데 이런 발급 기관을 **CA(Certificate authority)**라고 한다. CA의 인증서를 발급받는것은 당연 무료가 아니다.
- self-signed SSL 인증서는 **자체적으로 발급받은 인증서이며, 로그인 및 기타 개인 계정 인증 정보를 암호화**한다. 당연히 브라우저는 신뢰할 수 없다고 판단해 접속시 보안 경고가 발생한다.
- self-signed SSL 인증서를 만드는 방법은 몇 가지가 있는데, 무료 오픈소스인 `openssl` 을 이용해 쉽게 만들수 있다.
    - HTTPS를 위해 필요한 `개인키(.key)`, `서면요청파일(.csr)`, `인증서파일(.crt)`을 openssl이 발급해준다.

### 6.1. openssl 설치

```
apt-get -y install openssl
```

### 6.2. 개인키 및 인증서 생성

```
openssl req -newkey rsa:4096 -days 365 -nodes -x509 -subj "/C=KR/ST=Seoul/L=Seoul/O=42Seoul/OU=Lee/CN=localhost" -keyout localhost.dev.key -out localhost.dev.crt
```

localhost.dev.key 와 localhost.dev.crt가 생성된다. 옵션들을 하나하나 확인해보면,

- req : 인증서 요청 및 인증서 생성 유틸.
- newkey : 개인키를 생성하기 위한 옵션.
- keyout <키 파일 이름> : 키 파일 이름을 지정해 키 파일 생성.
- out <인증서 이름> : 인증서 이름을 지정해 인증서 생성.
- days 365 : 인증서의 유효기간을 작성하는 옵션.

### 6.3. 권한제한

```
mv localhost.dev.crt etc/ssl/certs/
mv localhost.dev.key etc/ssl/private/
chmod 600 etc/ssl/certs/localhost.dev.crt etc/ssl/private/localhost.dev.key
```

# 7. nginx에 SSL 설정 및 url redirection 추가

- `etc/nginx/sites-available/default` 파일을 수정해줄건데, 좀 더 편한 접근을 위해 vim을 설치해준다.
    
    ```
    apt-get -y install vim
    vim etc/nginx/sites-available/default
    ```
    
- `default` 파일에 https 연결을 위한 설정을 작성한다.
    
    원래는 서버 블록이 하나이며 80번 포트만 수신대기 상태인데, https 연결을 위해 443 포트를 수신대기하고 있는 서버 블록을 추가로 작성해야 한다.
    
    - `default` 수정 내용
        
        ```
        server {
        	listen 80;
        	listen [::]:80;
        
        	return 301 https://$host$request_uri;
        }
        
        server {
        	listen 443 ssl;
        	listen [::]:443 ssl;
        
        	# ssl 설정
        	ssl on;
        	ssl_certificate /etc/ssl/certs/localhost.dev.crt;
        	ssl_certificate_key /etc/ssl/private/localhost.dev.key;
        
        	# 서버의 root디렉토리 설정
        	root /var/www/html;
        
        	# 읽을 파일 목록
        	index index.html index.htm index.nginx-debian.html;
        
        	server_name ft_server;
        	location / {
        		try_files $uri $uri/ =404;
        	}
        }
        ```
        
        - 80번 포트로 수신되면 443 포트로 리다이렉션 시켜준다.
        - 443 포트를 위한 서버 블록에는 ssl on 과 인증서의 경로를 작성해준다. 나머지는 기존에 있던 설정 그대로.
    
- 바뀐 설정을 nginx에 적용한다
    
    ```
    service nginx reload
    service nginx start
    ```
    
- 브라우저에서 [https://localhost](https://localhost/) 로 접속했을 때 경고문구가 뜨면 성공.

# 8. php-fpm 설치 및 nginx 설정

- php란?
    
    대표적인 **서버 사이드 스크립트 언어**.
    
- CGI(공통 게이트웨이 인터페이스) 란?
    
    nginx는 웹서버이기 때문에 정적 콘텐츠밖에 다루지 못한다. 동적 페이지를 구현하기 위해서는 웹 서버 대신 동적 콘텐츠를 읽은 뒤 html로 변환시켜 웹 서버에게 다시 전달해주는 **외부 프로그램(php 모듈)**이 필요하다. 이런 **연결 과정의 방법 혹은 규약을 정의한 것이 CGI**이다.
    
    ![Untitled](https://s3-us-west-2.amazonaws.com/secure.notion-static.com/cdea487d-ed20-45f6-86c9-d43671033cbf/Untitled.png)
    
- php-fpm (PHP FastCGI Process Manager) 란?
    
    일반 CGI 보다 빠른 처리가 가능한 FastCGI. 
    
    정리하자면,`php-fpm` 을 통해 **nginx와 php를 연동시켜 우리의 웹 서버가 정적 콘텐츠 뿐만 아니라 동적 콘텐츠를 다룰 수 있도록** 만드는 것이다.
    

```
apt-get install php-fpm
```

위 명령으로 php-fpm 7.3 버전을 설치해주고 nginx default 파일에 php 처리를 위한 설정을 추가한다.

```
vim /etc/nginx/sites-available/default
```

- `default` 수정 내용
    
    ```
    server {
    	listen 80;
    	listen [::]:80;
    
    	return 301 https://$host$request_uri;
    }
    
    server {
    	listen 443 ssl;
    	listen [::]:442 ssl;
    
    	# ssl setting
    	ssl on;
    	ssl_certificate /etc/ssl/certs/localhost.dev.crt;
    	ssl_certificate_key /etc/ssl/private/localhost.dev.key;
    
    	# Set root dir of server
    	root /var/www/html;
    
    	# Auto index
    	index index.html index.htm index.nginx-debian.html **index.php**;
    
    	server_name ft_server;
    	location / {
    		try_files $uri $uri/ =404;
    	}
    
    	**# PHP 추가
    	location ~ \.php$ {
    		include snippets/fastcgi-php.conf;
    		fastcgi_pass unix:/var/run/php/php7.3-fpm.sock;
    	}**
    }
    ```
    

# 9. nginx autoindex 설정

- autoindex 가 뭔지 알고싶다면 먼저 웹서버가 리소스 매핑과 접근을 어떻게 하는지 부터 알아야한다.

> **웹 서버는 어떻게 수 많은 리소스 중 요청에 알맞은 콘텐츠를 제공할까?**
> 
> 
> 일반적으로 웹 서버 파일 시스템의 특별한 한 폴더를 웹 콘텐츠를 위해 사용한다. 이 폴더를 `문서루트` 혹은 `docroot`라고 부른다. 리소스 매핑의 가장 단순한 형태는 요청 URI를 `dotroot` 안에 있는 파일의 이름으로 사용하는 것이다.
> 
> 만약 파일이 아닌 디렉토리를 가리키는 url에 대한 요청을 받았을 때는, 요청한 url에 대응되는 디렉토리 안에서 `index.html` 혹은 `index.htm`으로 이름 붙은 파일을 찾아 그 파일의 콘텐츠를 반환한다. 이를 **autoindex** 라고 부른다.
> 

그래서 **우리는 autoindex 기능을 켜줘야한다**. nginx default 파일에서 location / 부분에  `autoindex on` 을 추가한다.

```
vim /etc/nginx/sites-available/default
```

- `default` 수정 내용
    
    ```
    server {
    	listen 80;
    	listen [::]:80;
    
    	return 301 https://$host$request_uri;
    }
    
    server {
    	listen 443 ssl;
    	listen [::]:442 ssl;
    
    	# ssl setting
    	ssl on;
    	ssl_certificate /etc/ssl/certs/localhost.dev.crt;
    	ssl_certificate_key /etc/ssl/private/localhost.dev.key;
    
    	# Set root dir of server
    	root /var/www/html;
    
    	# Auto index
    	index index.html index.htm index.nginx-debian.html index.php;
    
    	server_name ft_server;
    	location / {
    	**# autoindex on 추가
    		autoindex on;**
    		try_files $uri $uri/ =404;
    	}
    
    	# PHP 추가
    	location ~ \.php$ {
    		include snippets/fastcgi-php.conf;
    		fastcgi_pass unix:/var/run/php/php7.3-fpm.sock;
    	}
    }
    ```
    

- 만약 autoindex가 꺼져 있거나 해당 디렉토리에 index 목록에 해당하는 파일이 없다면, 웹 서버는 자동으로 그 디렉토리의 파일들을 `크기`, `변경일`, `해당 파일에 대한 링크`와 함께 열거한 HTML 파일을 반환한다.
- 루트 디렉터리인 /var/www/html 에 존재하는 index.ngiinx-debian.html 을 주석처리해보면, 읽을 파일이 없다고 생각하고 아래처럼 전체 파일 목록을 반환하는 것을 확인할 수 있다.

![Untitled](https://s3-us-west-2.amazonaws.com/secure.notion-static.com/bb1dc767-7e5d-4edf-94cb-ba32091541bf/Untitled.png)

# 10. MariaDB(mysql) 설치

[[MySQL]사용자 계정 생성 및 삭제](https://damduc.tistory.com/4)

# 12. phpMyAdmin 설치
