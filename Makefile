CFLAGS = -O3 -g0
CPPFLAGS = -I$(CONDA_PREFIX)/include -I$(HTSDIR)
HTSDIR = htslib
HTSLIB = $(HTSDIR)/libhts.a
LDLIBS = $(HTSLIB) -lpthread -lz -lm -lbz2 -llzma -lcurl -lcrypto
LDFLAGS  = -no-pie -L$(CONDA_PREFIX)/lib

all: $(HTSLIB) pbwt

PBWT_COMMIT_HASH = ""
ifneq "$(wildcard .git)" ""
PBWT_COMMIT_HASH = $(shell git describe --always --long --dirty)
version.h: $(if $(wildcard version.h),$(if $(findstring "$(PBWT_COMMIT_HASH)",$(shell cat version.h)),,force))
endif

version.h:
	echo '#define PBWT_COMMIT_HASH "$(PBWT_COMMIT_HASH)"' > $@

force:

test: all
	./test/test.pl

PBWT_OBJS = pbwtMain.o pbwtCore.o pbwtSample.o pbwtIO.o pbwtMatch.o pbwtImpute.o pbwtPaint.o pbwtLikelihood.o pbwtMerge.o pbwtGeneticMap.o pbwtHtslib.o
UTILS_OBJS = hash.o dict.o array.o utils.o
UTILS_HEADERS = utils.h array.h dict.h hash.h
AUTOZYG_OBJS = autozygExtract.o

pbwt: $(PBWT_OBJS) $(UTILS_OBJS)
	$(LINK.c) $^ $(LDLIBS) -o $@

pbwtMain.o: version.h
$(PBWT_OBJS): pbwt.h $(UTILS_HEADERS)
$(UTILS_OBJS): utils.h $(UTILS_HEADERS)

autozygExtract: $(AUTOZYG_OBJS)
	$(LINK.c) $^ $(LDLIBS) -o $@

install: all
	install -d $(PREFIX)
	install pbwt $(PREFIX)

clean:
	$(RM) *.o pbwt *~ version.h

.PHONY: all test clean force install

# Rule to fetch and build htslib if it's missing
$(HTSLIB):
	@echo ">>> Cloning htslib into $(HTSDIR) (if needed)..."
	@if [ ! -d $(HTSDIR) ]; then \
		git clone --recurse-submodules https://github.com/samtools/htslib.git $(HTSDIR) ; \
	else \
		cd $(HTSDIR) && git submodule update --init --recursive ; \
	fi
	@echo ">>> Building htslib statically (no shared lib, no debug)..."
	@$(MAKE) -C $(HTSDIR) libhts.a \
  	CFLAGS="-O2 -g0 -I$(CONDA_PREFIX)/include" \
  	CPPFLAGS="-I$(CONDA_PREFIX)/include" \
  	LDFLAGS="-L$(CONDA_PREFIX)/lib" \
  	NO_SHARED=1	

