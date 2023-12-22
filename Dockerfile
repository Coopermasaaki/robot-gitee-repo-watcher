FROM openeuler/openeuler:23.03 as BUILDER
RUN dnf update -y && \
    dnf install -y golang && \
    go env -w GOPROXY=https://goproxy.cn,direct

MAINTAINER zengchen1024<chenzeng765@gmail.com>

# build binary
WORKDIR /go/src/github.com/opensourceways/robot-gitee-repo-watcher
COPY . .
RUN GO111MODULE=on CGO_ENABLED=0 go build -a -o robot-gitee-repo-watcher -buildmode=pie --ldflags "-s -linkmode 'external' -extldflags '-Wl,-z,now'" .

# copy binary config and utils
FROM openeuler/openeuler:22.03
RUN dnf -y update && \
    dnf in -y shadow && \
    dnf remove -y gdb-gdbserver && \
    groupadd -g 1000 repo-watcher && \
    useradd -u 1000 -g repo-watcher -s /sbin/nologin -m repo-watcher && \
    echo > /etc/issue && echo > /etc/issue.net && echo > /etc/motd && \
    mkdir /home/repo-watcher -p && \
    chmod 700 /home/repo-watcher && \
    chown repo-watcher:repo-watcher /home/repo-watcher && \
    echo 'set +o history' >> /root/.bashrc && \
    sed -i 's/^PASS_MAX_DAYS.*/PASS_MAX_DAYS   90/' /etc/login.defs && \
    rm -rf /tmp/*

USER repo-watcher

WORKDIR /opt/app

COPY  --chown=repo-watcher --from=BUILDER /go/src/github.com/opensourceways/robot-gitee-repo-watcher/robot-gitee-repo-watcher /opt/app/robot-gitee-repo-watcher

RUN chmod 550 /opt/app/robot-gitee-repo-watcher && \
    echo "umask 027" >> /home/repo-watcher/.bashrc && \
    echo 'set +o history' >> /home/repo-watcher/.bashrc

ENTRYPOINT ["/opt/app/robot-gitee-repo-watcher"]
