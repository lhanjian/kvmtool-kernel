#ifndef KVM__GTK3_H
#define KVM__GTK3_H

#include "kvm/util.h"


#ifdef CONFIG_HAS_GTK3
int kvm_gtk_init(struct kvm *kvm);
int kvm_gtk_exit(struct kvm *kvm);
#else

#endif

#endif /* KVM__GTK3_H */
