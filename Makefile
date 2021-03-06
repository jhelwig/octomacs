EMACS=emacs

EMACS_CLEAN=-Q
EMACS_BATCH=$(EMACS_CLEAN) --batch
TESTS=

CURL=curl --silent
WORK_DIR=$(shell pwd)
PACKAGE_NAME=$(shell basename $(WORK_DIR))
AUTOLOADS_FILE=$(PACKAGE_NAME)-autoloads.el
TRAVIS_FILE=.travis.yml
TEST_DIR=test
TEST_DEP_1=ert
TEST_DEP_1_STABLE_URL=http://bzr.savannah.gnu.org/lh/emacs/emacs-24/download/head:/ert.el-20110112160650-056hnl9qhpjvjicy-2/ert.el
TEST_DEP_1_LATEST_URL=https://raw.github.com/emacsmirror/emacs/master/lisp/emacs-lisp/ert.el
TEST_DEP_2=el-mock
TEST_DEP_2_STABLE_URL=http://www.emacswiki.org/emacs/download/el-mock.el
TEST_DEP_2_LATEST_URL=http://www.emacswiki.org/emacs/download/el-mock.el

.PHONY : build downloads downloads-latest autoloads test-autoloads test-travis \
         test test-interactive clean edit test-dep-1 test-dep-2 test-dep-3     \
         test-dep-4 test-dep-5 test-dep-6 test-dep-7 test-dep-8 test-dep-9

build :
	$(EMACS) $(EMACS_BATCH) --eval             \
	    "(progn                                \
	      (setq byte-compile-error-on-warn t)  \
	      (batch-byte-compile))" *.el

test-dep-1 :
	@cd $(TEST_DIR)                                      && \
	$(EMACS) $(EMACS_BATCH)  -L . -L .. -l $(TEST_DEP_1) || \
	(echo "Can't load test dependency $(TEST_DEP_1).el, run 'make downloads' to fetch it" ; exit 1)

test-dep-2 :
	@cd $(TEST_DIR)                                      && \
	$(EMACS) $(EMACS_BATCH)  -L . -L .. -l $(TEST_DEP_2) || \
	(echo "Can't load test dependency $(TEST_DEP_2).el, run 'make downloads' to fetch it" ; exit 1)

downloads :
	$(CURL) '$(TEST_DEP_1_STABLE_URL)' > $(TEST_DIR)/$(TEST_DEP_1).el
	$(CURL) '$(TEST_DEP_2_STABLE_URL)' > $(TEST_DIR)/$(TEST_DEP_2).el

downloads-latest :
	$(CURL) '$(TEST_DEP_1_LATEST_URL)' > $(TEST_DIR)/$(TEST_DEP_1).el
	$(CURL) '$(TEST_DEP_2_LATEST_URL)' > $(TEST_DIR)/$(TEST_DEP_2).el

autoloads :
	$(EMACS) $(EMACS_BATCH) --eval                       \
	    "(progn                                          \
	      (setq generated-autoload-file \"$(WORK_DIR)/$(AUTOLOADS_FILE)\") \
	      (update-directory-autoloads \"$(WORK_DIR)\"))"

test-autoloads : autoloads
	@$(EMACS) $(EMACS_BATCH) -L . -l "./$(AUTOLOADS_FILE)"      || \
	 ( echo "failed to load autoloads: $(AUTOLOADS_FILE)" && false )

test-travis :
	@if test -z "$$TRAVIS" && test -e $(TRAVIS_FILE); then travis-lint $(TRAVIS_FILE); fi

test : test-dep-1 test-dep-2 test-autoloads
	@cd $(TEST_DIR)                                   && \
	(for test_lib in *-tests.el; do                      \
	    $(EMACS) $(EMACS_BATCH) -L . -L .. -l cl -l $(TEST_DEP_1) -l $$test_lib --eval \
	    "(flet ((ert--print-backtrace (&rest args)       \
	      (insert \"no backtrace in batch mode\")))      \
	       (ert-run-tests-batch-and-exit '(and \"$(TESTS)\" (not (tag :interactive)))))" || exit 1; \
	done)

clean :
	@rm -f $(AUTOLOADS_FILE) *.elc *~ */*.elc */*~ $(TEST_DIR)/$(TEST_DEP_1).el            \
        $(TEST_DIR)/$(TEST_DEP_2).el $(TEST_DIR)/$(TEST_DEP_3).el $(TEST_DIR)/$(TEST_DEP_4).el \
        $(TEST_DIR)/$(TEST_DEP_5).el $(TEST_DIR)/$(TEST_DEP_6).el $(TEST_DIR)/$(TEST_DEP_7).el \
        $(TEST_DIR)/$(TEST_DEP_8).el $(TEST_DIR)/$(TEST_DEP_9).el
