unit FidoApp.Constants;

interface

uses
  FidoApp.Types,

  Spring.Collections;

type
  Constants = record
  public const
    API_PREFIX = '/api';

    JWT_ISSUER = 'Fido App example';
    JWT_ACCESS_TOKEN_LIFETIME_SECS = 60 * 15;

    HEADER_AUTHORIZATION = 'Authorization';
    HEADER_REFRESHTOKEN = 'Refresh-Token';

    CLAIM_TYPE = 'type';
    CLAIM_TYPE_ACCESS = 'access';
    CLAIM_TYPE_REFRESH = 'refresh';
    CLAIM_USERID = 'userid';
    CLAIM_USERROLE = 'role';
    CLAIM_PERMISSIONS = 'permissions';

    ROLE_USER = 'user';
    ROLE_ADMIN = 'admin';

    PERMISSION_CAN_CHANGE_USER_STATE = 'CanChangeUserState';
    PERMISSION_CAN_SET_USER_ROLE = 'CanSetUSerRole';
    PERMISSION_CAN_GET_ALL_USERS = 'CanGetAllUsers';

    SPermission: array[Permission] of string = (
      PERMISSION_CAN_CHANGE_USER_STATE,
      PERMISSION_CAN_SET_USER_ROLE,
      PERMISSION_CAN_GET_ALL_USERS);

    ROLE_DEFAULT = ROLE_USER;

    TIMEOUT = INFINITE; //20000;
  end;

implementation

end.
