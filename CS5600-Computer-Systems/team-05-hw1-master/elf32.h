/*
 * file:        elf32.h
 * description: easier-to-use version of the 32-bit parts of elf.h
 * license:     GPL 2.1 or higher, derived from the GNU C Library
 */
#ifndef __ELF32_H__
#define __ELF32_H__
#include <stdint.h>

/* force 16 and 32-bit enumerated types
 */
#define __enum_16__ __attribute__((aligned (2))) __attribute__((__packed__))
#define __enum_32__ __attribute__((aligned (4))) __attribute__((__packed__))

/* file type
 */
enum ftype {
    ET_NONE = 0,
    ET_REL = 1,
    ET_EXEC = 2,
    ET_DYN = 3,
    ET_CORE = 4
} __enum_16__ ;

/* machine type - ignore all the others
 */
enum mtype {
    EM_386 = 3
} __enum_16__ ;

/* ELF only has one version
 */
enum vrsion {
    EV_CURRENT = 1
} __enum_16__;

/* class and data encoding are bytes 4 and 5 of e_ident
 */
enum ei {
    EI_CLASS =      4,          /* File class byte index */
    EI_DATA =       5,          /* Data encoding byte index */
};

enum eiclass {
    ELFCLASSNONE =  0,          /* Invalid class */
    ELFCLASS32 =    1,          /* 32-bit objects */
    ELFCLASS64 =    2,          /* 64-bit objects */
    ELFCLASSNUM =   3,
};

enum eidata {
    ELFDATANONE =   0,          /* Invalid data encoding */
    ELFDATA2LSB =   1,          /* 2's complement, little endian */
    ELFDATA2MSB =   2,          /* 2's complement, big endian */
};

/* the ELF header itself
 */
struct elf32_ehdr {
  unsigned char e_ident[16];            /* Magic number and other info */
  enum ftype    e_type;                 /* Object file type */
  enum mtype    e_machine;              /* Architecture */
  uint32_t      e_version;              /* Object file version */
  void *        e_entry;                /* Entry point virtual address */
  uint32_t      e_phoff;                /* Program header table file offset */
  uint32_t      e_shoff;                /* Section header table file offset */
  uint32_t      e_flags;                /* Processor-specific flags */
  uint16_t      e_ehsize;               /* ELF header size in bytes */
  uint16_t      e_phentsize;            /* Program header table entry size */
  uint16_t      e_phnum;                /* Program header table entry count */
  uint16_t      e_shentsize;            /* Section header table entry size */
  uint16_t      e_shnum;                /* Section header table entry count */
  uint16_t      e_shstrndx;             /* Section header string table index */
};

/* program header table
 */
enum ptype {
    PT_NULL =       0,               /* Program header table entry unused */
    PT_LOAD =       1,               /* Loadable program segment */
    PT_DYNAMIC =    2,               /* Dynamic linking information */
    PT_INTERP =     3,               /* Program interpreter */
    PT_NOTE =       4,               /* Auxiliary information */
    PT_SHLIB =      5,               /* Reserved */
    PT_PHDR =       6,               /* Entry for header table itself */
    PT_TLS =        7,               /* Thread-local storage segment */
    PT_NUM =        8,               /* Number of defined types */
    PT_LOOS =       0x60000000,      /* Start of OS-specific */
    PT_GNU_EH_FRAME = 0x6474e550,    /* GCC .eh_frame_hdr segment */
    PT_GNU_STACK =  0x6474e551,      /* Indicates stack executability */
    PT_GNU_RELRO =  0x6474e552,      /* Read-only after relocation */
    PT_LOSUNW =     0x6ffffffa,
    PT_SUNWBSS =    0x6ffffffa,      /* Sun Specific segment */
    PT_SUNWSTACK =  0x6ffffffb,      /* Stack segment */
    PT_HISUNW =     0x6fffffff,
    PT_HIOS =       0x6fffffff,      /* End of OS-specific */
    PT_LOPROC =     0x70000000,      /* Start of processor-specific */
    PT_HIPROC =     0x7fffffff       /* End of processor-specific */
};

enum pflag {
    PF_X =          (1 << 0),        /* Segment is executable */
    PF_W =          (1 << 1),        /* Segment is writable */
    PF_R =          (1 << 2)         /* Segment is readable */
};

struct elf32_phdr {
  enum ptype  p_type;                 /* Segment type */
  uint32_t    p_offset;               /* Segment file offset */
  void *      p_vaddr;                /* Segment virtual address */
  void *      p_paddr;                /* Segment physical address */
  uint32_t    p_filesz;               /* Segment size in file */
  uint32_t    p_memsz;                /* Segment size in memory */
  uint32_t    p_flags;                /* Segment flags */
  uint32_t    p_align;                /* Segment alignment */
};

/* section header table
 */
enum shtype {
    SHT_NULL = 0,             /* Section header table entry unused */
    SHT_PROGBITS = 1,
    SHT_SYMTAB = 2, 
    SHT_STRTAB = 3,
    SHT_RELA = 4,
    SHT_HASH = 5,
    SHT_DYNAMIC = 6,
    SHT_NOTE = 7,
    SHT_NOBITS = 8,
    SHT_REL = 9,
    SHT_SHLIB = 10,
    SHT_DYNSYM = 11,
    SHT_INIT_ARRAY = 14,
    SHT_FINI_ARRAY = 15,
    SHT_PREINIT_ARRAY = 16,
    SHT_GROUP = 17,
    SHT_SYMTAB_SHNDX = 18
} __enum_32__ ;

enum shflag {
    SHF_WRITE = (1 << 0),
    SHF_ALLOC = (1 << 1),
    SHF_EXECINSTR = (1 << 2),
    SHF_MERGE = (1 << 4),
    SHF_STRINGS = (1 << 5),
    SHF_INFO_LINK = (1 << 6),
    SHF_LINK_ORDER = (1 << 7),
    SHF_GROUP = (1 << 9),
    SHF_TLS = (1 << 10)
} __enum_32__;

struct elf32_section {
  uint32_t    sh_name;                /* Section name (string tbl index) */
  enum shtype sh_type;                /* Section type */
  uint32_t    sh_flags;               /* Section flags */
  void *      sh_addr;                /* Section virtual addr at execution */
  uint32_t    sh_offset;              /* Section file offset */
  uint32_t    sh_size;                /* Section size in bytes */
  uint32_t    sh_link;                /* Link to another section */
  uint32_t    sh_info;                /* Additional section information */
  uint32_t    sh_addralign;           /* Section alignment */
  uint32_t    sh_entsize;             /* Entry size if section holds table */
};

/* symbol table structure. This isn't completely converted yet
 */
struct elf32_sym {
  uint32_t    st_name;                /* Symbol name (string tbl index) */
  void *      st_value;               /* Symbol value */
  uint32_t    st_size;                /* Symbol size */
  uint8_t     st_info;                /* Symbol type and binding */
  uint8_t     st_other;               /* Symbol visibility */
  uint16_t    st_shndx;               /* Section index */
};

enum dtag {
    DT_NULL =       0,               /* Marks end of dynamic section */
    DT_NEEDED =     1,               /* Name of needed library */
    DT_PLTRELSZ =   2,               /* Size in bytes of PLT relocs */
    DT_PLTGOT =     3,               /* Processor defined value */
    DT_HASH =       4,               /* Address of symbol hash table */
    DT_STRTAB =     5,               /* Address of string table */
    DT_SYMTAB =     6,               /* Address of symbol table */
    DT_RELA =       7,               /* Address of Rela relocs */
    DT_RELASZ =     8,               /* Total size of Rela relocs */
    DT_RELAENT =    9,               /* Size of one Rela reloc */
    DT_STRSZ =      10,              /* Size of string table */
    DT_SYMENT =     11,              /* Size of one symbol table entry */
    DT_INIT =       12,              /* Address of init function */
    DT_FINI =       13,              /* Address of termination function */
    DT_SONAME =     14,              /* Name of shared object */
    DT_RPATH =      15,              /* Library search path (deprecated) */
    DT_SYMBOLIC =   16,              /* Start symbol search here */
    DT_REL =        17,              /* Address of Rel relocs */
    DT_RELSZ =      18,              /* Total size of Rel relocs */
    DT_RELENT =     19,              /* Size of one Rel reloc */
    DT_PLTREL =     20,              /* Type of reloc in PLT */
    DT_DEBUG =      21,              /* For debugging; unspecified */
    DT_TEXTREL =    22,              /* Reloc might modify .text */
    DT_JMPREL =     23,              /* Address of PLT relocs */
    DT_BIND_NOW =   24,              /* Process relocations of object */
    DT_INIT_ARRAY = 25,              /* Array with addresses of init fct */
    DT_FINI_ARRAY = 26,              /* Array with addresses of fini fct */
    DT_INIT_ARRAYSZ =7,              /* Size in bytes of DT_INIT_ARRAY */
    DT_FINI_ARRAYSZ =8,              /* Size in bytes of DT_FINI_ARRAY */
    DT_RUNPATH =    29,              /* Library search path */
    DT_FLAGS =      30,              /* Flags for the object being loaded */
    DT_ENCODING =   32,              /* Start of encoded range */
    DT_PREINIT_ARRAY = 32,           /* Array with addresses of preinit fct*/
    DT_PREINIT_ARRAYSZ = 33          /* size in bytes of DT_PREINIT_ARRAY */
};

struct elf32_dyn {
  enum dtag   d_tag;                  /* Dynamic entry type */
  union
    {
      uint32_t d_val;                 /* Integer value */
      void *   d_ptr;                 /* Address value */
    } d_un;
};

/* need to convert this... */
enum relo {
    R_386_NONE =         0,     /* No reloc */
    R_386_32 =           1,     /* Direct 32 bit  */
    R_386_PC32 =         2,     /* PC relative 32 bit */
    R_386_GOT32 =        3,     /* 32 bit GOT entry */
    R_386_PLT32 =        4,     /* 32 bit PLT address */
    R_386_COPY =         5,     /* Copy symbol at runtime */
    R_386_GLOB_DAT =     6,     /* Create GOT entry */
    R_386_JMP_SLOT =     7,     /* Create PLT entry */
    R_386_RELATIVE =     8,     /* Adjust by program base */
    R_386_GOTOFF =       9,     /* 32 bit offset to GOT */
    R_386_GOTPC =        10,    /* 32 bit PC relative offset to GOT */
    R_386_32PLT =        11,
    R_386_TLS_TPOFF =    14,    /* Offset in static TLS block */
    R_386_TLS_IE =       15,    /* Address of GOT entry for static TLS
                                   block offset */
    R_386_TLS_GOTIE =    16,    /* GOT entry for static TLS block
                                   offset */
    R_386_TLS_LE =       17,    /* Offset relative to static TLS
                                   block */
    R_386_TLS_GD =       18,    /* Direct 32 bit for GNU version of
                                   general dynamic thread local data */
    R_386_TLS_LDM =      19,    /* Direct 32 bit for GNU version of
                                   local dynamic thread local data
                                   in LE code */
    R_386_16 =           20,
    R_386_PC16 =         21,
    R_386_8 =            22,
    R_386_PC8 =          23,
    R_386_TLS_GD_32 =    24,    /* Direct 32 bit for general dynamic
                                   thread local data */
    R_386_TLS_GD_PUSH =  25,    /* Tag for pushl in GD TLS code */
    R_386_TLS_GD_CALL =  26,    /* Relocation for call to
                                   __tls_get_addr() */
    R_386_TLS_GD_POP =   27,    /* Tag for popl in GD TLS code */
    R_386_TLS_LDM_32 =   28,    /* Direct 32 bit for local dynamic
                                   thread local data in LE code */
    R_386_TLS_LDM_PUSH = 29,    /* Tag for pushl in LDM TLS code */
    R_386_TLS_LDM_CALL = 30,    /* Relocation for call to
                                   __tls_get_addr() in LDM code */
    R_386_TLS_LDM_POP =  31,    /* Tag for popl in LDM TLS code */
    R_386_TLS_LDO_32 =   32,    /* Offset relative to TLS block */
    R_386_TLS_IE_32 =    33,    /* GOT entry for negated static TLS
                                   block offset */
    R_386_TLS_LE_32 =    34,    /* Negated offset relative to static
                                   TLS block */
    R_386_TLS_DTPMOD32 = 35,    /* ID of module containing symbol */
    R_386_TLS_DTPOFF32 = 36,    /* Offset in TLS block */
    R_386_TLS_TPOFF32 =  37,    /* Negated offset in static TLS block */

    R_386_TLS_GOTDESC =  39,    /* GOT offset for TLS descriptor.  */
    R_386_TLS_DESC_CALL = 40,   /* Marker of call through TLS
                                   descriptor for
                                   relaxation.  */
    R_386_TLS_DESC =     41,    /* TLS descriptor containing
                                   pointer to code and to
                                   argument, returning the TLS
                                   offset for the symbol.  */ 
    R_386_IRELATIVE =    42     /* Adjust indirectly by program base */
};

#endif  /* __ELF32_H__ */
