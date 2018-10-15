#include <mruby.h>
#include <mruby/irep.h>
#include <mruby/dump.h>
#include <mruby/array.h>
#include "sheeter.h"

int main(int argc, char* argv[])
{
    mrb_value ARGV;
    mrb_state *mrb = mrb_open();

    ARGV = mrb_ary_new_capa(mrb, argc);
    for (int i = 1; i < argc; i++) {
      mrb_ary_push(mrb, ARGV, mrb_str_new_cstr(mrb, argv[i]));
    }
    mrb_define_global_const(mrb, "ARGV", ARGV);

    mrb_value obj = mrb_load_irep(mrb,SHEETER);

    if (mrb->exc) {
      if (mrb_undef_p(obj)) {
        mrb_p(mrb, mrb_obj_value(mrb->exc));
      } else {
        mrb_print_error(mrb);
      }
    }

    return 0;
}
