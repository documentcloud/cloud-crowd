module CloudCrowd
  
  class Error < RuntimeError;       end;
  class ActionNotFound < Error;     end;
  class StatusUnspecified < Error;  end;
  
end