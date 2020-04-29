FROM adminer

# Switch to the root user so we can install additional packages.
USER root

# Add labels so OpenShift recognises this as an S2I builder image.
LABEL io.k8s.description="S2I builder for Adminer (adminer)." \
      io.k8s.display-name="Adminer (adminer)" \
      io.openshift.expose-services="8080:http" \
      io.openshift.tags="builder,adminer,php" \
      io.openshift.s2i.scripts-url="image:///opt/app-root/s2i/bin"

# Copy in S2I builder scripts
COPY s2i /opt/app-root/s2i
RUN chmod +x /opt/app-root/s2i/bin/*

# Adjust permissions on /etc/passwd so writable by group root.
RUN chmod g+w /etc/passwd

# Revert the user but set it to be an integer user ID else the S2I build
# process will reject the builder image as can't tell if user name
# really maps to user ID for root.

USER 1000

# Override command to startup Adminer. The original is wrapped
# so we can set an environment variable for notebook password.

CMD [ "/opt/app-root/s2i/bin/run" ]