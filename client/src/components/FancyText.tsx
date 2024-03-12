import { makeStyles, Text, TextProps } from "@fluentui/react-components";

const useStyles = makeStyles({
  fancy: {
    fontSize: "1.125rem",
    fontFamily: "var(--base-font-family)",
    fontWeight: 600,
    fontStyle: "normal",
    lineHeight: "1.688rem",
    marginTop: "-0.1rem",
    textDecorationColor: "none",
    textDecorationLine: "none",
    textTransform: "none",
    color: "var(--color-title-font)",
  },
});

export const FancyText = ({
  children,
  className,
  block,
  as,
  ...rest
}: TextProps) => {
  const classes = useStyles();
  return (
    <Text
      {...rest}
      className={`${classes.fancy} ${className}`}
      as="p"
      block={true}
    >
      {children}
    </Text>
  );
};
