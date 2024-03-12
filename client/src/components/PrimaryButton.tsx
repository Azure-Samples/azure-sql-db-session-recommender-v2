import { Button, ButtonProps, makeStyles } from "@fluentui/react-components";

const useStyles = makeStyles({
  button: {
    boxShadow: "0 0 1px #0009, 0 1px 2px #0003",
  },
});

export const PrimaryButton = ({ children, ...rest }: ButtonProps) => {
  const classes = useStyles();
  return (
    <Button
      {...rest}
      type="submit"
      appearance="primary"
      className={classes.button}
    >
      {children}
    </Button>
  );
};
