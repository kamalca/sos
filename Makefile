#
# Makefile for sos system support tools
#

NAME	= sos
VERSION := $(shell echo `awk '/^Version:/ {print $$2}' sos.spec`)
MAJOR   := $(shell echo $(VERSION) | cut -f 1 -d '.')
MINOR   := $(shell echo $(VERSION) | cut -f 2 -d '.')
RELEASE := $(shell echo `awk '/^Release:/ {gsub(/\%.*/,""); print $2}' sos.spec`)
REPO = https://github.com/sosreport/sos

SUBDIRS = po sos sos/policies sos/report sos/report/plugins sos/collector sos/collector/clusters docs
PYFILES = $(wildcard *.py)
# OS X via brew
# MSGCAT = /usr/local/Cellar/gettext/0.18.1.1/bin/msgcat
MSGCAT = msgcat

DIST_BUILD_DIR = dist-build
RPM_DEFINES = --define "_topdir %(pwd)/$(DIST_BUILD_DIR)" \
	--define "_builddir %{_topdir}" \
	--define "_rpmdir %{_topdir}" \
	--define "_srcrpmdir %{_topdir}" \
	--define "_specdir %{_topdir}" \
	--define "_sourcedir %{_topdir}"
RPM = rpmbuild
RPM_WITH_DIRS = $(RPM) $(RPM_DEFINES)
ARCHIVE_DIR = $(DIST_BUILD_DIR)/$(NAME)-$(VERSION)
DEB_ARCHIVE_DIR = $(DIST_BUILD_DIR)/$(NAME)report-$(VERSION)

SRC_BUILD = $(DIST_BUILD_DIR)/sdist
PO_DIR = $(SRC_BUILD)/sos/po

.PHONY: docs
docs:
	make -C docs html man

.PHONY: build
build:
	for d in $(SUBDIRS); do make -C $$d; [ $$? = 0 ] || exit 1 ; done

.PHONY: install
install:
	mkdir -p $(DESTDIR)/usr/sbin
	mkdir -p $(DESTDIR)/usr/share/man/man1
	mkdir -p $(DESTDIR)/usr/share/man/man5
	mkdir -p $(DESTDIR)/usr/share/$(NAME)/extras
	@gzip -c man/en/sos.1 > sos.1.gz
	@gzip -c man/en/sos-report.1 > sos-report.1.gz
	@gzip -c man/en/sos-collect.1 > sos-collect.1.gz
	@gzip -c man/en/sos.conf.5 > sos.conf.5.gz
	@rm -f sosreport.1.gz sos-collector.1.gz
	@ln -s sos-report.1.gz sosreport.1.gz
	@ln -s sos-collect.1.gz sos-collector.1.gz
	mkdir -p $(DESTDIR)/etc
	install -m755 bin/sosreport $(DESTDIR)/usr/sbin/sosreport
	install -m755 bin/sos $(DESTDIR)/usr/sbin/sos
	install -m644 sos.1.gz $(DESTDIR)/usr/share/man/man1/.
	install -m644 sos-report.1.gz $(DESTDIR)/usr/share/man/man1/.
	install -m644 sosreport.1.gz $(DESTDIR)/usr/share/man/man1/.
	install -m644 sos-collect.1.gz $(DESTDIR)/usr/share/man/man1/.
	install -m644 sos-collector.1.gz $(DESTDIR)/usr/share/man/man1/.
	install -m644 sos.conf.5.gz $(DESTDIR)/usr/share/man/man5/.
	install -m644 AUTHORS README.md $(DESTDIR)/usr/share/$(NAME)/.
	install -m644 $(NAME).conf $(DESTDIR)/etc/$(NAME).conf
	for d in $(SUBDIRS); do make DESTDIR=`cd $(DESTDIR); pwd` -C $$d install; [ $$? = 0 ] || exit 1; done

$(NAME)-$(VERSION).tar.gz: clean
	@mkdir -p $(ARCHIVE_DIR)
	@tar -cv bin sos docs man po sos.conf AUTHORS LICENSE README.md sos.spec Makefile | tar -x -C $(ARCHIVE_DIR)
	@tar Ccvzf $(DIST_BUILD_DIR) $(DIST_BUILD_DIR)/$(NAME)-$(VERSION).tar.gz $(NAME)-$(VERSION) --exclude-vcs

$(NAME)report_$(VERSION).orig.tar.gz: clean
	@mkdir -p $(DEB_ARCHIVE_DIR)
	@tar --exclude-vcs \
             --exclude=.travis.yml \
             --exclude=debian \
             --exclude=$(DIST_BUILD_DIR) -cv . | tar -x -C $(DEB_ARCHIVE_DIR)
	@tar Ccvzf $(DIST_BUILD_DIR) $(DIST_BUILD_DIR)/$(NAME)report_$(VERSION).orig.tar.gz $(NAME)report-$(VERSION)
	@mv $(DIST_BUILD_DIR)/$(NAME)report_$(VERSION).orig.tar.gz .
	@rm -Rf $(DIST_BUILD_DIR)

clean:
	@rm -fv *~ .*~ changenew ChangeLog.old $(NAME)-$(VERSION).tar.gz sos.1.gz sos-report.1.gz sos-collect.1.gz sos.conf.5.gz
	@rm -rf rpm-build
	@for i in `find . -iname *.pyc`; do \
		rm -f $$i; \
	done; \
	for d in $(SUBDIRS); do make -C $$d clean ; done

srpm: clean $(NAME)-$(VERSION).tar.gz
	$(RPM_WITH_DIRS) -ts $(DIST_BUILD_DIR)/$(NAME)-$(VERSION).tar.gz

rpm: clean $(NAME)-$(VERSION).tar.gz
	$(RPM_WITH_DIRS) -tb $(DIST_BUILD_DIR)/$(NAME)-$(VERSION).tar.gz

po: clean
	mkdir -p $(PO_DIR)
	for po in `ls po/*.po`; do \
		$(MSGCAT) -p -o $(PO_DIR)/sos_$$(basename $$po | awk -F. '{print $$1}').properties $$po; \
	done; \

	cp $(PO_DIR)/sos_en.properties $(PO_DIR)/sos_en_US.properties
	cp $(PO_DIR)/sos_en.properties $(PO_DIR)/sos.properties

test:
	nosetests -v --with-cover --cover-package=sos --cover-html
