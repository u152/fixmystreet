    validation_rules = {
        title: { required: true },
        detail: { required: true },
        update: { required: true },
        password_register: {
          remote: {
            url: '/auth/common_password',
            type: 'post'
          }
        }
    };
