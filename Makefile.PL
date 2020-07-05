use 5.018004;
use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    NAME              => 'Nano::Pl',
    VERSION_FROM      => 'lib/App/Nanopl.pm', # finds $VERSION
    #PL_FILES          => 
    PREREQ_PM         => {}, # e.g., Module::Name => 1.1
    ($] >= 5.005 ?     ## Add these new keywords supported since 5.005
      (ABSTRACT_FROM  => 'lib/App/Nanopl.pm', # retrieve abstract from module
       AUTHOR         => 'ben <ben@11elf.com>') : ()),
);
